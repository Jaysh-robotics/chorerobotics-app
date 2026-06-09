"""
BLE GATT Server implementation using `bless` library.

`bless` provides a cross-platform BLE peripheral server that works on:
- Linux (BlueZ via D-Bus)
- macOS (CoreBluetooth)
- Windows (WinRT)

This allows testing on a MacBook before deploying to Jetson Nano.

Services:
    1. Robot Info Service (CHOR0001) — static identity data
    2. Pairing Service (CHOR0002) — pairing state machine
    3. Command Service (CHOR0003) — joystick, task, E-Stop
    4. Telemetry Service (CHOR0004) — sensor data streaming
    5. WiFi Config Service (CHOR0005) — WiFi setup during onboarding
"""

import asyncio
import json
import logging
import struct
from typing import Optional, Callable, Dict, Any, List

from bless import (
    BlessServer,
    BlessGATTCharacteristic,
    GATTCharacteristicProperties,
    GATTAttributePermissions,
)

from ..models.robot_state import RobotState, PairingPhase
from ..models.telemetry import TelemetrySnapshot
from ..models.command import DriveCommand, EStopCommand, BladeCommand
from ..config import (
    BLE_DEVICE_NAME_PREFIX,
    BLE_SERVICE_ROBOT_INFO,
    BLE_SERVICE_PAIRING,
    BLE_SERVICE_COMMAND,
    BLE_SERVICE_TELEMETRY,
    BLE_SERVICE_WIFI_CONFIG,
    BLE_CHAR_SERIAL_NUMBER,
    BLE_CHAR_MODEL,
    BLE_CHAR_FIRMWARE_VERSION,
    BLE_CHAR_ROBOT_NAME,
    BLE_CHAR_ATTACHMENT_TYPE,
    BLE_CHAR_PAIRING_STATE,
    BLE_CHAR_PAIRING_CODE,
    BLE_CHAR_PAIRING_RESULT,
    BLE_CHAR_PAIRING_TOKEN,
    BLE_CHAR_DRIVE_COMMAND,
    BLE_CHAR_TASK_COMMAND,
    BLE_CHAR_ESTOP,
    BLE_CHAR_COMMAND_ACK,
    BLE_CHAR_BLADE_CONTROL,
    BLE_CHAR_CORE_TELEMETRY,
    BLE_CHAR_GPS_POSITION,
    BLE_CHAR_MOTOR_SPEEDS,
    BLE_CHAR_EXTENDED_TELEMETRY,
    BLE_CHAR_WIFI_SCAN,
    BLE_CHAR_WIFI_CREDENTIALS,
    BLE_CHAR_WIFI_STATUS,
    BLE_CHAR_WIFI_IP_ADDRESS,
    BLE_CHAR_DIAGNOSTICS,
    BLE_CHAR_TASK_PROGRESS,
    ROBOT_SERIAL,
    ROBOT_MODEL,
    ROBOT_FIRMWARE_VERSION,
    TELEMETRY_BLE_CORE_HZ,
    TELEMETRY_BLE_GPS_HZ,
    TELEMETRY_BLE_MOTOR_HZ,
    TELEMETRY_BLE_EXTENDED_HZ,
)

logger = logging.getLogger(__name__)


class GattServer:
    """BLE GATT peripheral server using bless.

    Manages all 5 GATT services, handles reads/writes/notifications,
    and streams telemetry to connected clients.
    """

    def __init__(
        self,
        robot_state: RobotState,
        telemetry: TelemetrySnapshot,
    ) -> None:
        self._robot_state = robot_state
        self._telemetry = telemetry
        self._server: Optional[BlessServer] = None
        self._loop: Optional[asyncio.AbstractEventLoop] = None
        self._is_running: bool = False
        self._is_advertising: bool = False
        self._connected_device: Optional[str] = None

        # Notification tasks
        self._notification_tasks: List[asyncio.Task] = []

        # Callbacks
        self.on_drive_command: Optional[Callable[[DriveCommand], None]] = None
        self.on_task_command: Optional[Callable[[Dict[str, Any]], None]] = None
        self.on_estop: Optional[Callable[[EStopCommand], None]] = None
        self.on_blade_command: Optional[Callable[[BladeCommand], None]] = None
        self.on_pairing_code_received: Optional[Callable[[str], None]] = None
        self.on_wifi_credentials_received: Optional[Callable[[str, str], None]] = None
        self.on_client_connected: Optional[Callable[[str], None]] = None
        self.on_client_disconnected: Optional[Callable[[], None]] = None

        # Device name
        self._device_name = f"{BLE_DEVICE_NAME_PREFIX}{ROBOT_SERIAL[-5:]}"

    async def start(self) -> None:
        """Start the BLE GATT server with all services."""
        logger.info(f"Starting BLE GATT server as '{self._device_name}'")

        # Capture the running loop so write handlers (called by CoreBluetooth
        # on a non-asyncio thread) can dispatch coroutines back to us safely.
        self._loop = asyncio.get_running_loop()
        self._server = BlessServer(name=self._device_name, loop=self._loop)
        self._server.read_request_func = self._handle_read
        self._server.write_request_func = self._handle_write

        # Add all services and characteristics
        await self._register_services()

        # Start advertising
        await self._server.start()
        self._is_running = True
        self._is_advertising = True

        logger.info(f"BLE GATT server started. Advertising as: {self._device_name}")
        logger.info(f"Services: RobotInfo, Pairing, Command, Telemetry, WiFiConfig")

    async def stop(self) -> None:
        """Stop the BLE GATT server."""
        logger.info("Stopping BLE GATT server")
        self._is_running = False
        self._is_advertising = False

        # Cancel notification tasks
        for task in self._notification_tasks:
            if not task.done():
                task.cancel()
        self._notification_tasks.clear()

        if self._server:
            await self._server.stop()

    async def _register_services(self) -> None:
        """Register all GATT services and characteristics."""

        # ── Service 1: Robot Info (read-only identity) ──
        await self._server.add_new_service(BLE_SERVICE_ROBOT_INFO)

        await self._add_read_char(BLE_SERVICE_ROBOT_INFO, BLE_CHAR_SERIAL_NUMBER,
                                   bytearray(ROBOT_SERIAL.encode()))
        await self._add_read_char(BLE_SERVICE_ROBOT_INFO, BLE_CHAR_MODEL,
                                   bytearray(ROBOT_MODEL.encode()))
        await self._add_read_char(BLE_SERVICE_ROBOT_INFO, BLE_CHAR_FIRMWARE_VERSION,
                                   bytearray(ROBOT_FIRMWARE_VERSION.encode()))
        await self._add_readwrite_char(BLE_SERVICE_ROBOT_INFO, BLE_CHAR_ROBOT_NAME,
                                        bytearray(self._robot_state.robot_name.encode()))
        await self._add_read_char(BLE_SERVICE_ROBOT_INFO, BLE_CHAR_ATTACHMENT_TYPE,
                                   bytearray(self._robot_state.attachment_type.encode()))

        # ── Service 2: Pairing ──
        await self._server.add_new_service(BLE_SERVICE_PAIRING)

        await self._add_notify_char(BLE_SERVICE_PAIRING, BLE_CHAR_PAIRING_STATE, bytearray([0]))
        await self._add_write_char(BLE_SERVICE_PAIRING, BLE_CHAR_PAIRING_CODE)
        await self._add_notify_char(BLE_SERVICE_PAIRING, BLE_CHAR_PAIRING_RESULT, bytearray([0]))
        await self._add_read_char(BLE_SERVICE_PAIRING, BLE_CHAR_PAIRING_TOKEN, bytearray(b""))

        # ── Service 3: Command ──
        await self._server.add_new_service(BLE_SERVICE_COMMAND)

        await self._add_write_char(BLE_SERVICE_COMMAND, BLE_CHAR_DRIVE_COMMAND)
        await self._add_write_char(BLE_SERVICE_COMMAND, BLE_CHAR_TASK_COMMAND)
        await self._add_write_char(BLE_SERVICE_COMMAND, BLE_CHAR_ESTOP)
        await self._add_notify_char(BLE_SERVICE_COMMAND, BLE_CHAR_COMMAND_ACK, bytearray(b""))
        await self._add_write_char(BLE_SERVICE_COMMAND, BLE_CHAR_BLADE_CONTROL)

        # ── Service 4: Telemetry ──
        await self._server.add_new_service(BLE_SERVICE_TELEMETRY)

        await self._add_notify_char(BLE_SERVICE_TELEMETRY, BLE_CHAR_CORE_TELEMETRY, bytearray(20))
        await self._add_notify_char(BLE_SERVICE_TELEMETRY, BLE_CHAR_GPS_POSITION, bytearray(12))
        await self._add_notify_char(BLE_SERVICE_TELEMETRY, BLE_CHAR_MOTOR_SPEEDS, bytearray(8))
        await self._add_notify_char(BLE_SERVICE_TELEMETRY, BLE_CHAR_EXTENDED_TELEMETRY, bytearray(b"{}"))
        await self._add_notify_char(BLE_SERVICE_TELEMETRY, BLE_CHAR_DIAGNOSTICS, bytearray(b"{}"))
        await self._add_notify_char(BLE_SERVICE_TELEMETRY, BLE_CHAR_TASK_PROGRESS, bytearray(b"{}"))

        # ── Service 5: WiFi Config ──
        await self._server.add_new_service(BLE_SERVICE_WIFI_CONFIG)

        await self._add_notify_char(BLE_SERVICE_WIFI_CONFIG, BLE_CHAR_WIFI_SCAN, bytearray(b"[]"))
        await self._add_write_char(BLE_SERVICE_WIFI_CONFIG, BLE_CHAR_WIFI_CREDENTIALS)
        await self._add_notify_char(BLE_SERVICE_WIFI_CONFIG, BLE_CHAR_WIFI_STATUS, bytearray([0]))
        await self._add_read_char(BLE_SERVICE_WIFI_CONFIG, BLE_CHAR_WIFI_IP_ADDRESS, bytearray(b"0.0.0.0"))

        logger.info("All 5 GATT services registered (25 characteristics)")

    # ── Characteristic registration helpers ──

    async def _add_read_char(self, service_uuid: str, char_uuid: str, initial: bytes | bytearray) -> None:
        await self._server.add_new_characteristic(
            service_uuid, char_uuid, GATTCharacteristicProperties.read,
            initial, GATTAttributePermissions.readable,
        )

    async def _add_write_char(self, service_uuid: str, char_uuid: str) -> None:
        # CoreBluetooth: writable chars must NOT have cached values (pass None)
        await self._server.add_new_characteristic(
            service_uuid, char_uuid,
            GATTCharacteristicProperties.write | GATTCharacteristicProperties.write_without_response,
            None, GATTAttributePermissions.writeable,
        )

    async def _add_readwrite_char(self, service_uuid: str, char_uuid: str, initial: bytes | bytearray) -> None:
        # CoreBluetooth: read+write chars must NOT have cached values
        await self._server.add_new_characteristic(
            service_uuid, char_uuid,
            GATTCharacteristicProperties.read | GATTCharacteristicProperties.write,
            None, GATTAttributePermissions.readable | GATTAttributePermissions.writeable,
        )

    async def _add_notify_char(self, service_uuid: str, char_uuid: str, initial: bytes | bytearray) -> None:
        # CoreBluetooth: notify chars are "dynamic" — no cached value
        await self._server.add_new_characteristic(
            service_uuid, char_uuid,
            GATTCharacteristicProperties.read | GATTCharacteristicProperties.notify,
            None, GATTAttributePermissions.readable,
        )

    # ── Read/Write handlers ──

    def _handle_read(self, characteristic: BlessGATTCharacteristic, **kwargs) -> bytearray:
        """Handle BLE read requests."""
        uuid = characteristic.uuid.upper()
        logger.debug(f"BLE read: {uuid}")

        handlers = {
            BLE_CHAR_SERIAL_NUMBER: lambda: bytearray(ROBOT_SERIAL.encode()),
            BLE_CHAR_MODEL: lambda: bytearray(ROBOT_MODEL.encode()),
            BLE_CHAR_FIRMWARE_VERSION: lambda: bytearray(ROBOT_FIRMWARE_VERSION.encode()),
            BLE_CHAR_ROBOT_NAME: lambda: bytearray(self._robot_state.robot_name.encode()),
            BLE_CHAR_ATTACHMENT_TYPE: lambda: bytearray(self._robot_state.attachment_type.encode()),
            BLE_CHAR_PAIRING_STATE: lambda: bytes([self._robot_state.pairing.phase.value]),
            BLE_CHAR_PAIRING_RESULT: lambda: self._get_pairing_result_bytes(),
            BLE_CHAR_PAIRING_TOKEN: lambda: self._get_pairing_token_bytes(),
        }

        handler = handlers.get(uuid)
        if handler:
            return bytearray(handler())

        # For notify characteristics, return current value
        return characteristic.value

    def _handle_write(self, characteristic: BlessGATTCharacteristic, value: Any, **kwargs) -> None:
        """Handle BLE write requests."""
        uuid = characteristic.uuid.upper()
        data = bytes(value) if not isinstance(value, bytes) else value

        logger.debug(f"BLE write: {uuid} ({len(data)} bytes)")

        if uuid == BLE_CHAR_ROBOT_NAME:
            new_name = data.decode("utf-8").strip()[:50]
            self._robot_state.robot_name = new_name
            logger.info(f"Robot renamed: {new_name}")

        elif uuid == BLE_CHAR_PAIRING_CODE:
            code = data.decode("utf-8").strip()
            logger.info(f"Pairing code received: {code}")
            if self.on_pairing_code_received and self._loop is not None:
                # CoreBluetooth calls this handler from a non-asyncio thread.
                # Dispatch the coroutine back to our main loop safely.
                asyncio.run_coroutine_threadsafe(
                    self._async_pairing_code(code), self._loop
                )

        elif uuid == BLE_CHAR_DRIVE_COMMAND:
            if len(data) >= 4:
                cmd = DriveCommand.from_ble_bytes(data)
                if self.on_drive_command:
                    self.on_drive_command(cmd)

        elif uuid == BLE_CHAR_TASK_COMMAND:
            try:
                command = json.loads(data.decode("utf-8"))
                if self.on_task_command:
                    self.on_task_command(command)
            except (json.JSONDecodeError, UnicodeDecodeError) as e:
                logger.error(f"Invalid task command: {e}")

        elif uuid == BLE_CHAR_ESTOP:
            if len(data) >= 1:
                cmd = EStopCommand.from_ble_byte(data[0])
                logger.warning(f"E-Stop via BLE: activate={cmd.activate}")
                if self.on_estop:
                    self.on_estop(cmd)

        elif uuid == BLE_CHAR_BLADE_CONTROL:
            if len(data) >= 1:
                cmd = BladeCommand.from_ble_byte(data[0])
                if self.on_blade_command:
                    self.on_blade_command(cmd)

        elif uuid == BLE_CHAR_WIFI_CREDENTIALS:
            try:
                creds = json.loads(data.decode("utf-8"))
                ssid = creds.get("ssid", "")
                password = creds.get("password", "")
                logger.info(f"WiFi credentials for: {ssid}")
                if self.on_wifi_credentials_received:
                    self.on_wifi_credentials_received(ssid, password)
            except (json.JSONDecodeError, UnicodeDecodeError) as e:
                logger.error(f"Invalid WiFi credentials: {e}")

    async def _async_pairing_code(self, code: str) -> None:
        """Async wrapper for pairing code callback."""
        if self.on_pairing_code_received:
            await self.on_pairing_code_received(code)

    # ── Data getters ──

    def _get_pairing_result_bytes(self) -> bytes:
        if self._robot_state.pairing.is_paired:
            return bytes([1])
        if self._robot_state.pairing.phase == PairingPhase.FAILED:
            return bytes([2])
        return bytearray([0])

    def _get_pairing_token_bytes(self) -> bytes:
        token = self._robot_state.pairing.pairing_token
        if token and self._robot_state.pairing.is_paired:
            return token.encode("utf-8")
        return bytearray(b"")

    # ── Notifications ──

    def start_telemetry_notifications(self) -> None:
        """Start periodic telemetry notifications."""
        self._notification_tasks.append(
            asyncio.create_task(self._notify_loop(
                BLE_CHAR_CORE_TELEMETRY, 1.0 / TELEMETRY_BLE_CORE_HZ,
                lambda: self._telemetry.pack_core_ble(),
            ))
        )
        self._notification_tasks.append(
            asyncio.create_task(self._notify_loop(
                BLE_CHAR_GPS_POSITION, 1.0 / TELEMETRY_BLE_GPS_HZ,
                lambda: self._telemetry.gps.pack_bytes() if hasattr(self._telemetry, 'gps') else bytearray(12),
            ))
        )
        self._notification_tasks.append(
            asyncio.create_task(self._notify_loop(
                BLE_CHAR_MOTOR_SPEEDS, 1.0 / TELEMETRY_BLE_MOTOR_HZ,
                lambda: self._telemetry.motors.pack_bytes() if hasattr(self._telemetry, 'motors') else bytearray(8),
            ))
        )
        logger.info("Telemetry notifications started")

    async def _notify_loop(self, char_uuid: str, interval: float, data_fn) -> None:
        """Send notifications at fixed interval."""
        while self._is_running:
            try:
                if self._server:
                    data = data_fn()
                    self._server.get_characteristic(char_uuid).value = bytearray(data)
                    self._server.update_value(BLE_SERVICE_TELEMETRY, char_uuid)
                await asyncio.sleep(interval)
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Notification error ({char_uuid}): {e}")
                await asyncio.sleep(interval)

    async def notify_pairing_state(self, state: int) -> None:
        """Notify the app of a pairing state change."""
        if self._server:
            char = self._server.get_characteristic(BLE_CHAR_PAIRING_STATE)
            if char:
                char.value = bytearray([state])
                self._server.update_value(BLE_SERVICE_PAIRING, BLE_CHAR_PAIRING_STATE)
                logger.debug(f"Notified pairing state: {state}")

    async def notify_pairing_result(self, result: int) -> None:
        """Notify the app of pairing result (0=pending, 1=success, 2=failed)."""
        if self._server:
            char = self._server.get_characteristic(BLE_CHAR_PAIRING_RESULT)
            if char:
                char.value = bytearray([result])
                self._server.update_value(BLE_SERVICE_PAIRING, BLE_CHAR_PAIRING_RESULT)

    async def notify_wifi_status(self, status: int) -> None:
        """Notify WiFi connection status."""
        if self._server:
            char = self._server.get_characteristic(BLE_CHAR_WIFI_STATUS)
            if char:
                char.value = bytearray([status])
                self._server.update_value(BLE_SERVICE_WIFI_CONFIG, BLE_CHAR_WIFI_STATUS)
