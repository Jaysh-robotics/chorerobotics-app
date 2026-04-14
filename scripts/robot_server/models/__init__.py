"""
Data models for the ChoreRobotics Robot Server.

All structured data exchanged between modules uses dataclasses defined here.
This ensures type safety and provides a clear contract between the BLE, WiFi,
Firebase, ROS2, and hardware modules.
"""

from .telemetry import (
    TelemetrySnapshot,
    BatteryTelemetry,
    MotionTelemetry,
    GpsTelemetry,
    MotorTelemetry,
    SystemTelemetry,
)
from .command import (
    DriveCommand,
    TaskStartCommand,
    TaskStopCommand,
    BladeCommand,
    EStopCommand,
    DockCommand,
    MowParameters,
    PlowParameters,
    CollectParameters,
)
from .robot_state import (
    RobotState,
    TaskState,
    ConnectionState,
    PairingState,
    AlertEntry,
)

__all__ = [
    "TelemetrySnapshot",
    "BatteryTelemetry",
    "MotionTelemetry",
    "GpsTelemetry",
    "MotorTelemetry",
    "SystemTelemetry",
    "DriveCommand",
    "TaskStartCommand",
    "TaskStopCommand",
    "BladeCommand",
    "EStopCommand",
    "DockCommand",
    "MowParameters",
    "PlowParameters",
    "CollectParameters",
    "RobotState",
    "TaskState",
    "ConnectionState",
    "PairingState",
    "AlertEntry",
]
