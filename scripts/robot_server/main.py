"""
ChoreRobotics Robot Server -- Main Entry Point

Starts all robot server services and wires them together:
1. LED Controller (hardware GPIO)
2. BLE GATT Server (BlueZ D-Bus)
3. WiFi WebSocket Server (asyncio websockets)
4. Firebase Client (Admin SDK)
5. ROS2 Bridge (rclpy)

All services share:
    - RobotState: Central state machine
    - TelemetrySnapshot: Latest sensor data
    - Command routing: BLE/WiFi/Firebase -> ROS2

The server runs as a single asyncio event loop on the main thread.
ROS2 is integrated via rclpy's async executor.

Usage:
    python -m robot_server.main

    Or with environment overrides:
    CHOREROBOT_SERIAL=CR-MK1-00002 python -m robot_server.main
"""

import asyncio
import logging
import signal
import sys
from typing import Optional

from .config import (
    ROBOT_SERIAL,
    ROBOT_MODEL,
    ROBOT_FIRMWARE_VERSION,
    DEFAULT_ROBOT_NAME,
)
from .models.telemetry import TelemetrySnapshot
from .models.robot_state import RobotState
from .models.command import (
    DriveCommand,
    TaskStartCommand,
    TaskStopCommand,
    BladeCommand,
    EStopCommand,
    DockCommand,
)
from .hardware.led_controller import LedController
from .hardware.gpio import GpioManager
from .ble.gatt_server import GattServer
from .ble.pairing import PairingManager
from .ble.commands import BleCommandHandler
from .wifi.websocket_server import WebSocketServer
from .wifi.auth import WebSocketAuth
from .firebase.client import FirebaseClient
from .firebase.telemetry_uploader import TelemetryUploader
from .firebase.command_listener import CommandListener

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("chorerobot")


class RobotServer:
    """Main orchestrator for all robot server services.

    Initializes, starts, and manages the lifecycle of all subsystems.
    Routes commands from any input channel to the ROS2 autonomy stack.
    Routes telemetry from ROS2 to all output channels.

    Architecture:

        ┌─────────┐   ┌───────────┐   ┌──────────┐
        │   BLE   │   │ WebSocket │   │ Firebase │
        │  GATT   │   │  Server   │   │  Client  │
        └────┬────┘   └─────┬─────┘   └────┬─────┘
             │              │               │
             └──────┬───────┴───────┬───────┘
                    │               │
             ┌──────▼───────┐ ┌────▼──────┐
             │   Command    │ │ Telemetry │
             │   Router     │ │ Snapshot  │
             └──────┬───────┘ └────┬──────┘
                    │              │
             ┌──────▼──────────────▼──────┐
             │        ROS2 Bridge         │
             │   (subscriber + publisher) │
             └────────────────────────────┘
    """

    def __init__(self) -> None:
        """Initialize the robot server with all subsystems."""
        logger.info(f"Initializing robot server: {ROBOT_SERIAL} ({ROBOT_MODEL})")

        # Shared state
        self._robot_state = RobotState(robot_name=DEFAULT_ROBOT_NAME)
        self._telemetry = TelemetrySnapshot()

        # Hardware
        self._gpio = GpioManager()
        self._led = LedController()

        # BLE
        self._gatt_server = GattServer(self._robot_state, self._telemetry)
        self._pairing_manager = PairingManager(self._robot_state)
        self._ble_command_handler = BleCommandHandler(self._robot_state)

        # WiFi
        self._ws_auth = WebSocketAuth()
        self._ws_server = WebSocketServer(
            self._robot_state, self._telemetry, self._ws_auth
        )

        # Firebase
        self._firebase_client = FirebaseClient(ROBOT_SERIAL)
        self._telemetry_uploader = TelemetryUploader(
            self._firebase_client, self._telemetry, self._robot_state
        )
        self._command_listener = CommandListener(
            self._firebase_client, self._robot_state
        )

        # ROS2 bridge is initialized separately (requires rclpy.init)
        self._ros_publisher: Optional["RosCommandPublisher"] = None
        self._ros_subscriber: Optional["RosTelemetrySubscriber"] = None

        # Server state
        self._is_running = False
        self._shutdown_event = asyncio.Event()

    def _wire_callbacks(self) -> None:
        """Connect all callbacks between subsystems.

        This is the central wiring that connects:
        - BLE/WebSocket/Firebase command inputs -> command router
        - Command router -> ROS2 publisher
        - Pairing state changes -> LED controller
        - E-Stop -> all channels + LED + ROS2
        """
        # --- BLE callbacks ---
        # GATT server -> BLE command handler
        self._gatt_server.on_drive_command = self._ble_command_handler.handle_drive_command
        self._gatt_server.on_task_command = self._ble_command_handler.handle_task_command
        self._gatt_server.on_estop = self._ble_command_handler.handle_estop
        self._gatt_server.on_blade_command = self._ble_command_handler.handle_blade_command
        self._gatt_server.on_pairing_code_received = self._on_pairing_code_received

        # BLE command handler -> command router
        self._ble_command_handler.on_drive = self._handle_drive_command
        self._ble_command_handler.on_task_start = self._handle_task_start
        self._ble_command_handler.on_task_stop = self._handle_task_stop
        self._ble_command_handler.on_task_pause = self._handle_task_pause
        self._ble_command_handler.on_task_resume = self._handle_task_resume
        self._ble_command_handler.on_estop = self._handle_estop
        self._ble_command_handler.on_blade = self._handle_blade_command
        self._ble_command_handler.on_dock = self._handle_dock_command

        # --- WiFi WebSocket callbacks ---
        self._ws_server.on_drive_command = self._handle_drive_command
        self._ws_server.on_task_start = self._handle_task_start
        self._ws_server.on_task_stop = self._handle_task_stop
        self._ws_server.on_task_pause = self._handle_task_pause
        self._ws_server.on_task_resume = self._handle_task_resume
        self._ws_server.on_estop = self._handle_estop
        self._ws_server.on_blade_control = self._handle_blade_command
        self._ws_server.on_dock = self._handle_dock_command
        self._ws_server.on_zone_sync = self._handle_zone_sync
        self._ws_server.on_schedule_sync = self._handle_schedule_sync

        # --- Firebase command listener callbacks ---
        self._command_listener.on_task_start = self._handle_task_start
        self._command_listener.on_task_stop = self._handle_task_stop
        self._command_listener.on_task_pause = self._handle_task_pause
        self._command_listener.on_task_resume = self._handle_task_resume
        self._command_listener.on_estop = self._handle_estop
        self._command_listener.on_dock = self._handle_dock_command

        # --- Pairing callbacks ---
        self._pairing_manager.on_state_changed = self._led.on_pairing_state_changed
        self._pairing_manager.on_paired = self._on_pairing_complete

        # --- GATT server connection callbacks ---
        self._gatt_server.on_client_connected = self._on_ble_client_connected
        self._gatt_server.on_client_disconnected = self._on_ble_client_disconnected

    # =========================================================================
    # Command Router -- all commands from all channels come here
    # =========================================================================

    def _handle_drive_command(self, cmd: DriveCommand) -> None:
        """Route a drive command to ROS2.

        Called at up to 30Hz from BLE or WebSocket.
        NEVER called from Firebase (cloud latency too high).

        Args:
            cmd: Normalized drive command.
        """
        if self._ros_publisher:
            self._ros_publisher.publish_drive(cmd)

    def _handle_task_start(self, cmd: TaskStartCommand) -> None:
        """Route a task start command to ROS2.

        Args:
            cmd: Task start command with type, zone, and parameters.
        """
        logger.info(f"Task start: {cmd.task_type} in zone {cmd.zone_id} (via {cmd.source.value})")
        if self._ros_publisher:
            self._ros_publisher.publish_task_start(cmd)

    def _handle_task_stop(self, cmd: TaskStopCommand) -> None:
        """Route a task stop command to ROS2.

        Args:
            cmd: Task stop command with reason.
        """
        logger.info(f"Task stop: reason={cmd.reason} (via {cmd.source.value})")
        if self._ros_publisher:
            self._ros_publisher.publish_task_stop(cmd)

    def _handle_task_pause(self) -> None:
        """Route a task pause command to ROS2."""
        logger.info("Task pause")
        if self._ros_publisher:
            self._ros_publisher.publish_task_pause()

    def _handle_task_resume(self) -> None:
        """Route a task resume command to ROS2."""
        logger.info("Task resume")
        if self._ros_publisher:
            self._ros_publisher.publish_task_resume()

    def _handle_estop(self, cmd: EStopCommand) -> None:
        """Handle E-Stop command from any channel.

        E-Stop is the HIGHEST PRIORITY command:
        1. Immediately publish to ROS2 (stops all motors)
        2. Update robot state
        3. Set LED to red rapid flash
        4. Broadcast status to all channels
        5. Stop drive command forwarding

        Args:
            cmd: E-Stop command (activate or clear).
        """
        if cmd.activate:
            logger.warning(f"E-STOP ACTIVATED via {cmd.source.value}")

            # 1. Stop motors via ROS2
            if self._ros_publisher:
                self._ros_publisher.publish_estop(True)
                self._ros_publisher.publish_stop()  # zero velocity

            # 2. Update state
            source_name = f"app_{cmd.source.value}"
            self._robot_state.set_estop(source_name)

            # 3. LED
            self._led.on_estop(True)

            # 4. Broadcast to all connected clients
            asyncio.create_task(
                self._ws_server.broadcast_estop_status(
                    active=True,
                    source=source_name,
                    triggered_at=self._robot_state.estop_triggered_at_ms or 0,
                )
            )

        else:
            # E-Stop clear
            if not cmd.validate_clear():
                logger.warning("E-Stop clear rejected: invalid confirmation code")
                return

            logger.info(f"E-STOP CLEARED via {cmd.source.value}")

            # TODO: Run self-diagnostics before clearing
            # diagnostics_ok = await self._run_diagnostics()
            # if not diagnostics_ok:
            #     logger.error("E-Stop clear failed: diagnostics check failed")
            #     return

            # Clear state
            if self._ros_publisher:
                self._ros_publisher.publish_estop(False)
            self._robot_state.clear_estop()
            self._led.on_estop(False)

            asyncio.create_task(
                self._ws_server.broadcast_estop_status(
                    active=False,
                    source=f"app_{cmd.source.value}",
                    triggered_at=0,
                )
            )

    def _handle_blade_command(self, cmd: BladeCommand) -> None:
        """Handle blade toggle command.

        Safety check: blade commands from cloud are rejected.

        Args:
            cmd: Blade on/off command.
        """
        if not cmd.is_safe_source():
            logger.warning(f"Blade command rejected: unsafe source {cmd.source.value}")
            return

        if self._robot_state.estop_active:
            logger.warning("Blade command rejected: E-Stop active")
            return

        self._robot_state.blade_on = cmd.enabled
        if self._ros_publisher:
            self._ros_publisher.publish_blade(cmd.enabled)

    def _handle_dock_command(self, cmd: DockCommand) -> None:
        """Route a return-to-dock command to ROS2.

        Args:
            cmd: Dock command.
        """
        logger.info(f"Dock command via {cmd.source.value}")
        if self._ros_publisher:
            self._ros_publisher.publish_dock()

    def _handle_zone_sync(self, payload: dict) -> None:
        """Handle zone sync from WebSocket.

        Forwards zone definitions to ROS2 for the autonomy stack.

        Args:
            payload: Zone sync payload with zones list.
        """
        zones = payload.get("zones", [])
        logger.info(f"Zone sync: {len(zones)} zones received")
        if self._ros_publisher:
            self._ros_publisher.publish_zones(zones)

    def _handle_schedule_sync(self, payload: dict) -> None:
        """Handle schedule sync from WebSocket.

        Args:
            payload: Schedule sync payload with schedules list.
        """
        schedules = payload.get("schedules", [])
        logger.info(f"Schedule sync: {len(schedules)} schedules received")
        if self._ros_publisher:
            self._ros_publisher.publish_schedules(schedules)

    # =========================================================================
    # Pairing callbacks
    # =========================================================================

    async def _on_pairing_code_received(self, code: str) -> None:
        """Handle pairing code entry from BLE.

        Delegates to PairingManager for verification.

        Args:
            code: 6-digit code entered by the user.
        """
        result = await self._pairing_manager.verify_code(code)
        if result:
            await self._gatt_server.notify_pairing_result(1)  # SUCCESS
        else:
            await self._gatt_server.notify_pairing_result(2)  # FAILED

    def _on_pairing_complete(self, token: str) -> None:
        """Handle successful pairing.

        Stores the pairing token for WebSocket authentication.

        Args:
            token: 32-character hex pairing token.
        """
        self._ws_auth.set_token(token)
        logger.info("Pairing complete. WebSocket auth token set.")

    async def _on_ble_client_connected(self, device_address: str) -> None:
        """Handle BLE client connection.

        Args:
            device_address: BLE MAC address.
        """
        self._robot_state.connection.ble_connected = True
        self._robot_state.connection.ble_device_address = device_address
        await self._pairing_manager.on_device_connected(device_address)

    async def _on_ble_client_disconnected(self) -> None:
        """Handle BLE client disconnection."""
        self._robot_state.connection.ble_connected = False
        self._robot_state.connection.ble_device_address = None
        await self._pairing_manager.on_device_disconnected()

    # =========================================================================
    # Server Lifecycle
    # =========================================================================

    async def start(self) -> None:
        """Start all robot server services.

        Initialization order:
        1. GPIO and LED (hardware first)
        2. BLE GATT server (must advertise before app can connect)
        3. Pairing manager (initializes pairing state)
        4. WebSocket server (available after pairing provides token)
        5. Firebase client (cloud connectivity)
        6. Telemetry uploader (depends on Firebase)
        7. Command listener (depends on Firebase)
        8. Wire all callbacks

        The ROS2 bridge is initialized separately because it requires
        rclpy.init() which has its own lifecycle.
        """
        logger.info("=" * 60)
        logger.info(f"ChoreRobotics Robot Server v{__import__('robot_server').__version__}")
        logger.info(f"Serial: {ROBOT_SERIAL}")
        logger.info(f"Model: {ROBOT_MODEL}")
        logger.info(f"Firmware: {ROBOT_FIRMWARE_VERSION}")
        logger.info("=" * 60)

        self._is_running = True

        # Wire callbacks before starting services
        self._wire_callbacks()

        # 1. Hardware
        self._gpio.initialize()
        await self._led.initialize()

        # 2. BLE
        await self._gatt_server.start()

        # 3. Pairing
        await self._pairing_manager.initialize()

        # 4. WebSocket
        await self._ws_server.start()

        # 5. Firebase
        try:
            await self._firebase_client.initialize()
            self._robot_state.connection.cloud_connected = True

            # 6. Telemetry uploader
            await self._telemetry_uploader.start()

            # 7. Command listener
            await self._command_listener.start()

            # Load zones and schedules from Firestore
            zones = await self._firebase_client.get_zones()
            if zones and self._ros_publisher:
                self._ros_publisher.publish_zones(zones)

            schedules = await self._firebase_client.get_schedules()
            if schedules and self._ros_publisher:
                self._ros_publisher.publish_schedules(schedules)

        except Exception as e:
            logger.warning(f"Firebase initialization failed (offline mode): {e}")
            self._robot_state.connection.cloud_connected = False

        logger.info("Robot server started successfully")

    async def stop(self) -> None:
        """Stop all robot server services gracefully.

        Shutdown order is reverse of startup:
        7. Command listener
        6. Telemetry uploader
        5. Firebase client
        4. WebSocket server
        3. (Pairing manager -- no explicit shutdown needed)
        2. BLE GATT server
        1. LED and GPIO
        """
        logger.info("Shutting down robot server...")
        self._is_running = False

        await self._command_listener.stop()
        await self._telemetry_uploader.stop()
        await self._firebase_client.shutdown()
        await self._ws_server.stop()
        await self._gatt_server.stop()
        await self._led.shutdown()
        self._gpio.cleanup()

        logger.info("Robot server shutdown complete")

    async def run_forever(self) -> None:
        """Run the server until a shutdown signal is received.

        Registers signal handlers for SIGINT and SIGTERM.
        """
        loop = asyncio.get_event_loop()

        # Register signal handlers
        for sig in (signal.SIGINT, signal.SIGTERM):
            loop.add_signal_handler(sig, self._shutdown_event.set)

        await self.start()

        # Wait for shutdown signal
        await self._shutdown_event.wait()

        await self.stop()


def main() -> None:
    """Entry point for the robot server.

    Initializes the asyncio event loop and runs the server.
    """
    server = RobotServer()
    asyncio.run(server.run_forever())


if __name__ == "__main__":
    main()
