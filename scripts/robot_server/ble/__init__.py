"""
BLE GATT Server module.

Implements the Bluetooth Low Energy peripheral interface using BlueZ
over D-Bus on the Jetson Nano. The robot advertises as a BLE device
and exposes GATT services for robot info, pairing, commands, telemetry,
and WiFi configuration.

Architecture:
    BlueZ (Linux Bluetooth stack)
        |
    D-Bus interface
        |
    GattServer (gatt_server.py) -- registers services and characteristics
        |
    PairingManager (pairing.py) -- state machine for code-based pairing
        |
    BleCommandHandler (commands.py) -- processes incoming BLE commands
"""

from .gatt_server import GattServer
from .pairing import PairingManager
from .commands import BleCommandHandler

__all__ = ["GattServer", "PairingManager", "BleCommandHandler"]
