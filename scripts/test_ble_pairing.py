#!/usr/bin/env python3
"""
Test BLE Pairing — Run on MacBook to simulate the robot's BLE server.

This script starts a BLE GATT peripheral that the Flutter app can
discover and pair with. It simulates the full pairing flow:
1. Robot advertises as "ChoreBot-00001"
2. App discovers and connects
3. Robot generates 6-digit pairing code (printed to terminal)
4. User enters code in app
5. Robot verifies code and issues pairing token
6. LED states logged to terminal (simulated)

Usage:
    pip install bless
    python test_ble_pairing.py

Requires:
    macOS: Bluetooth must be enabled, terminal needs Bluetooth permission
    Linux: BlueZ 5.50+, run with sudo or add user to bluetooth group
"""

import asyncio
import logging
import sys
import os

# Add parent to path so we can import robot_server modules
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from robot_server.config import ROBOT_SERIAL, LED_STATE_DISCOVERABLE
from robot_server.models.robot_state import RobotState, PairingPhase
from robot_server.models.telemetry import TelemetrySnapshot
from robot_server.ble.gatt_server import GattServer
from robot_server.ble.pairing import PairingManager

# Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("test_ble")

# LED state names for terminal display
LED_NAMES = {
    0: "OFF",
    1: "DISCOVERABLE (White slow blink)",
    2: "FOUND (White fast blink)",
    3: "PAIRING (White double blink)",
    4: "AWAITING CODE (White solid)",
    5: "VERIFYING (White rapid blink)",
    6: "SUCCESS (Green 3 flashes → solid)",
    7: "WIFI SETUP (Green slow blink)",
    8: "COMPLETE (Green solid)",
    9: "FAILED (Red 3 flashes)",
    10: "E-STOP (Red rapid flash)",
}


def on_led_state_changed(state: int) -> None:
    """Simulated LED — just print to terminal."""
    name = LED_NAMES.get(state, f"UNKNOWN({state})")
    logger.info(f"💡 LED → {name}")


def on_paired(token: str) -> None:
    """Called when pairing succeeds."""
    logger.info(f"✅ PAIRED! Token: {token[:16]}...")
    logger.info("The app can now authenticate via WebSocket using this token.")


async def on_pairing_code(code: str, pairing_mgr: PairingManager, gatt: GattServer) -> None:
    """Called when app sends a pairing code."""
    logger.info(f"📱 App sent code: {code}")
    result = await pairing_mgr.verify_code(code)
    if result:
        await gatt.notify_pairing_result(1)  # SUCCESS
        logger.info("✅ Code correct!")
    else:
        await gatt.notify_pairing_result(2)  # FAILED
        logger.info("❌ Code incorrect!")


async def main():
    logger.info("=" * 50)
    logger.info("ChoreRobotics BLE Pairing Test")
    logger.info(f"Robot Serial: {ROBOT_SERIAL}")
    logger.info("=" * 50)
    logger.info("")
    logger.info("This script simulates the robot's BLE server.")
    logger.info("Open the Flutter app and go to BLE Scan screen.")
    logger.info("")

    # Create shared state
    robot_state = RobotState()
    telemetry = TelemetrySnapshot()

    # Create services
    gatt = GattServer(robot_state, telemetry)
    pairing = PairingManager(robot_state)

    # Wire callbacks
    pairing.on_state_changed = on_led_state_changed
    pairing.on_paired = on_paired

    # When app writes pairing code → verify it
    async def handle_code(code: str):
        await on_pairing_code(code, pairing, gatt)

    gatt.on_pairing_code_received = handle_code

    # When BLE client connects
    async def handle_connect(addr: str):
        logger.info(f"📱 Device connected: {addr}")
        await pairing.on_device_connected(addr)

        # Auto-start pairing and generate code
        code = await pairing.start_pairing()
        logger.info("")
        logger.info("╔══════════════════════════════════╗")
        logger.info(f"║   PAIRING CODE:  {code}          ║")
        logger.info("║   Enter this in the app          ║")
        logger.info("╚══════════════════════════════════╝")
        logger.info("")

        # Notify app of pairing state
        await gatt.notify_pairing_state(robot_state.pairing.phase.value)

    async def handle_disconnect():
        logger.info("📱 Device disconnected")
        await pairing.on_device_disconnected()

    gatt.on_client_connected = handle_connect
    gatt.on_client_disconnected = handle_disconnect

    # E-Stop handler
    def handle_estop(cmd):
        if cmd.activate:
            logger.warning("🚨 E-STOP ACTIVATED via BLE!")
            on_led_state_changed(10)
        else:
            logger.info("✅ E-STOP cleared")

    gatt.on_estop = handle_estop

    # Drive command handler
    def handle_drive(cmd):
        logger.info(f"🎮 Drive: x={cmd.linear_x:.2f} y={cmd.linear_y:.2f} rot={cmd.angular_z:.2f}")

    gatt.on_drive_command = handle_drive

    # Start
    try:
        await gatt.start()
        await pairing.initialize()

        logger.info("")
        logger.info("🔵 Robot is advertising. Waiting for app to connect...")
        logger.info("   Press Ctrl+C to stop.")
        logger.info("")

        # Run forever until Ctrl+C
        while True:
            await asyncio.sleep(1)

    except KeyboardInterrupt:
        logger.info("\nShutting down...")
    finally:
        await gatt.stop()
        logger.info("BLE server stopped.")


if __name__ == "__main__":
    asyncio.run(main())
