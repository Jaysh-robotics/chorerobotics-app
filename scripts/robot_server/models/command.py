"""
Command data models.

These dataclasses represent commands sent from the Flutter app to the robot
via BLE, WebSocket, or Firebase cloud commands. Each command type maps to
a specific ROS2 topic publication.

For BLE, the drive command uses a packed 4-byte binary format for minimal
latency at 30Hz. All other commands use JSON encoding.
"""

from dataclasses import dataclass, field
from typing import Optional, Dict, Any, List
from enum import Enum
import struct
import json
import uuid
import time


class CommandSource(Enum):
    """Source channel of a received command."""

    BLE = "ble"
    WEBSOCKET = "websocket"
    FIREBASE = "firebase"


class TaskType(Enum):
    """Type of autonomous task the robot can perform."""

    MOW = "mow"
    PLOW = "plow"
    COLLECT = "collect"


class StopReason(Enum):
    """Reason for stopping a task."""

    USER_REQUESTED = "user_requested"
    WEATHER = "weather"
    SCHEDULE_END = "schedule_end"
    BATTERY_LOW = "battery_low"
    OBSTACLE = "obstacle"
    CONNECTION_LOST = "connection_lost"
    ESTOP = "estop"


@dataclass
class DriveCommand:
    """Manual joystick drive command.

    Sent at 30Hz from the app during manual control mode.
    Maps to ROS2 geometry_msgs/msg/Twist on /cmd_vel topic.

    Over BLE: 4 packed bytes (see pack_ble_bytes / from_ble_bytes).
    Over WebSocket: JSON with float values (-1.0 to +1.0).
    Over Firebase: NEVER sent via cloud (latency too high for safety).
    """

    linear_x: float = 0.0
    """Forward (+) / backward (-) velocity, normalized -1.0 to +1.0."""

    linear_y: float = 0.0
    """Left (+) / right (-) strafe velocity, normalized -1.0 to +1.0. Reserved, not used."""

    angular_z: float = 0.0
    """Left (+) / right (-) rotation, normalized -1.0 to +1.0."""

    blade_on: bool = False
    """Whether the blade/attachment motor should be running."""

    turbo_mode: bool = False
    """If true, allow higher maximum velocity."""

    source: CommandSource = CommandSource.BLE
    """Which communication channel this command arrived on."""

    timestamp_ms: int = 0
    """Unix timestamp in milliseconds when the command was sent."""

    def __post_init__(self) -> None:
        if self.timestamp_ms == 0:
            self.timestamp_ms = int(time.time() * 1000)

    def pack_ble_bytes(self) -> bytes:
        """Pack into 4-byte BLE drive command characteristic.

        Byte 0: linear_x  (int8, -127 to +127)
        Byte 1: linear_y  (int8, -127 to +127)
        Byte 2: angular_z (int8, -127 to +127)
        Byte 3: flags     (uint8, bitfield)
        """
        from ..config import DRIVE_CMD_FLAG_BLADE_ON, DRIVE_CMD_FLAG_TURBO

        lx = int(max(-127, min(127, self.linear_x * 127)))
        ly = int(max(-127, min(127, self.linear_y * 127)))
        az = int(max(-127, min(127, self.angular_z * 127)))
        flags = 0
        if self.blade_on:
            flags |= DRIVE_CMD_FLAG_BLADE_ON
        if self.turbo_mode:
            flags |= DRIVE_CMD_FLAG_TURBO
        return struct.pack("<bbbB", lx, ly, az, flags)

    @classmethod
    def from_ble_bytes(cls, data: bytes) -> "DriveCommand":
        """Unpack from 4-byte BLE drive command characteristic.

        Args:
            data: 4 bytes from BLE write to CHOR0301 characteristic.

        Returns:
            DriveCommand with normalized float values.
        """
        from ..config import DRIVE_CMD_FLAG_BLADE_ON, DRIVE_CMD_FLAG_TURBO

        lx, ly, az, flags = struct.unpack("<bbbB", data[:4])
        return cls(
            linear_x=lx / 127.0,
            linear_y=ly / 127.0,
            angular_z=az / 127.0,
            blade_on=bool(flags & DRIVE_CMD_FLAG_BLADE_ON),
            turbo_mode=bool(flags & DRIVE_CMD_FLAG_TURBO),
            source=CommandSource.BLE,
        )

    @classmethod
    def from_websocket_dict(cls, payload: Dict[str, Any]) -> "DriveCommand":
        """Parse from WebSocket JSON message payload.

        Args:
            payload: The 'payload' field of a drive_command WebSocket message.

        Returns:
            DriveCommand with values from the JSON.
        """
        flags = payload.get("flags", {})
        return cls(
            linear_x=float(payload.get("linear_x", 0.0)),
            linear_y=float(payload.get("linear_y", 0.0)),
            angular_z=float(payload.get("angular_z", 0.0)),
            blade_on=bool(flags.get("blade_on", False)),
            turbo_mode=bool(flags.get("turbo_mode", False)),
            source=CommandSource.WEBSOCKET,
        )

    @classmethod
    def stop(cls) -> "DriveCommand":
        """Create a zero-velocity stop command (all axes zero).

        Used when the app releases the joystick or on E-Stop.
        """
        return cls(linear_x=0.0, linear_y=0.0, angular_z=0.0)

    def to_ros2_twist(self) -> Dict[str, float]:
        """Convert to ROS2 geometry_msgs/Twist-compatible dict.

        The actual max velocities are applied by the ROS2 node based on
        robot configuration. This command provides normalized values.

        Returns:
            Dict with linear and angular velocity components.
        """
        return {
            "linear_x": self.linear_x,
            "linear_y": self.linear_y,
            "angular_z": self.angular_z,
        }


@dataclass
class MowParameters:
    """Parameters for a mowing task.

    Matches the MowParameters interface in the Firestore schema.
    """

    pattern: str = "straight"
    """Mowing pattern: 'straight', 'diagonal', 'checker', 'spiral'."""

    angle_deg: float = 0.0
    """Stripe angle in degrees (0-180)."""

    overlap_pct: float = 15.0
    """Pass overlap as percentage (0-30)."""

    cutting_height_mm: int = 50
    """Blade cutting height in millimeters (25-100)."""

    def to_dict(self) -> Dict[str, Any]:
        return {
            "pattern": self.pattern,
            "angle_deg": self.angle_deg,
            "overlap_pct": self.overlap_pct,
            "cutting_height_mm": self.cutting_height_mm,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "MowParameters":
        return cls(
            pattern=data.get("pattern", "straight"),
            angle_deg=float(data.get("angle_deg", 0)),
            overlap_pct=float(data.get("overlap_pct", 15)),
            cutting_height_mm=int(data.get("cutting_height_mm", 50)),
        )


@dataclass
class PlowParameters:
    """Parameters for a snow plowing task.

    Matches the PlowParameters interface in the Firestore schema.
    """

    start_position: str = "entrance"
    """Start position: 'entrance', 'garage', 'center', 'custom'."""

    custom_start_lat: Optional[float] = None
    """Custom start point latitude (only if start_position is 'custom')."""

    custom_start_lng: Optional[float] = None
    """Custom start point longitude (only if start_position is 'custom')."""

    snow_depth: str = "medium"
    """Estimated snow depth: 'light', 'medium', 'heavy'."""

    disposal_direction: str = "right"
    """Snow disposal direction: 'left', 'right', 'pile_zone'."""

    pile_zone_id: Optional[str] = None
    """Zone ID for pile destination (only if disposal is 'pile_zone')."""

    def to_dict(self) -> Dict[str, Any]:
        result: Dict[str, Any] = {
            "start_position": self.start_position,
            "snow_depth": self.snow_depth,
            "disposal_direction": self.disposal_direction,
        }
        if self.custom_start_lat is not None:
            result["custom_start_point"] = {
                "lat": self.custom_start_lat,
                "lng": self.custom_start_lng,
            }
        if self.pile_zone_id is not None:
            result["pile_zone_id"] = self.pile_zone_id
        return result

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "PlowParameters":
        custom = data.get("custom_start_point")
        return cls(
            start_position=data.get("start_position", "entrance"),
            custom_start_lat=custom.get("lat") if custom else None,
            custom_start_lng=custom.get("lng") if custom else None,
            snow_depth=data.get("snow_depth", "medium"),
            disposal_direction=data.get("disposal_direction", "right"),
            pile_zone_id=data.get("pile_zone_id"),
        )


@dataclass
class CollectParameters:
    """Parameters for a leaf collection task.

    Matches the CollectParameters interface in the Firestore schema.
    """

    mode: str = "full_zone"
    """Collection mode: 'full_zone' or 'spot_clean'."""

    spot_clean_vertices: Optional[List[Dict[str, float]]] = None
    """Spot clean polygon vertices [{lat, lng}], only if mode is 'spot_clean'."""

    collection_mode: str = "mulch"
    """How to handle collected leaves: 'mulch' or 'bag'."""

    dump_point_lat: Optional[float] = None
    """Dump point latitude (only if collection_mode is 'bag')."""

    dump_point_lng: Optional[float] = None
    """Dump point longitude (only if collection_mode is 'bag')."""

    def to_dict(self) -> Dict[str, Any]:
        result: Dict[str, Any] = {
            "mode": self.mode,
            "collection_mode": self.collection_mode,
        }
        if self.spot_clean_vertices:
            result["spot_clean_vertices"] = self.spot_clean_vertices
        if self.dump_point_lat is not None:
            result["dump_point"] = {
                "lat": self.dump_point_lat,
                "lng": self.dump_point_lng,
            }
        return result

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "CollectParameters":
        dump = data.get("dump_point")
        return cls(
            mode=data.get("mode", "full_zone"),
            spot_clean_vertices=data.get("spot_clean_vertices"),
            collection_mode=data.get("collection_mode", "mulch"),
            dump_point_lat=dump.get("lat") if dump else None,
            dump_point_lng=dump.get("lng") if dump else None,
        )


@dataclass
class TaskStartCommand:
    """Command to start an autonomous task.

    Received from the app via WebSocket, BLE, or Firebase cloud command.
    Published to ROS2 /task/start topic.
    """

    command_id: str = ""
    """Unique command ID for acknowledgement correlation."""

    task_type: str = "mow"
    """Task type: 'mow', 'plow', 'collect'."""

    zone_id: str = ""
    """ID of the zone to operate in."""

    parameters: Optional[Dict[str, Any]] = None
    """Task-specific parameters (MowParameters, PlowParameters, or CollectParameters as dict)."""

    source: CommandSource = CommandSource.WEBSOCKET
    """Which communication channel this command arrived on."""

    timestamp_ms: int = 0

    def __post_init__(self) -> None:
        if not self.command_id:
            self.command_id = str(uuid.uuid4())
        if self.timestamp_ms == 0:
            self.timestamp_ms = int(time.time() * 1000)

    @classmethod
    def from_websocket_dict(cls, msg_id: str, payload: Dict[str, Any]) -> "TaskStartCommand":
        """Parse from WebSocket message."""
        return cls(
            command_id=msg_id,
            task_type=payload.get("task_type", "mow"),
            zone_id=payload.get("zone_id", ""),
            parameters=payload.get("parameters"),
            source=CommandSource.WEBSOCKET,
        )

    @classmethod
    def from_firebase_dict(cls, command_id: str, data: Dict[str, Any]) -> "TaskStartCommand":
        """Parse from Firestore command document payload."""
        payload = data.get("payload", {})
        return cls(
            command_id=command_id,
            task_type=payload.get("taskType", "mow"),
            zone_id=payload.get("zoneId", ""),
            parameters=payload.get("parameters"),
            source=CommandSource.FIREBASE,
        )

    def to_ros2_json(self) -> str:
        """Serialize parameters to JSON for ROS2 TaskCommand message."""
        return json.dumps(self.parameters or {})


@dataclass
class TaskStopCommand:
    """Command to stop the currently running task."""

    command_id: str = ""
    reason: str = "user_requested"
    source: CommandSource = CommandSource.WEBSOCKET
    timestamp_ms: int = 0

    def __post_init__(self) -> None:
        if not self.command_id:
            self.command_id = str(uuid.uuid4())
        if self.timestamp_ms == 0:
            self.timestamp_ms = int(time.time() * 1000)


@dataclass
class BladeCommand:
    """Command to toggle the blade/attachment motor on or off.

    Safety restriction: blade commands are NEVER accepted from Firebase
    (cloud). Only BLE and WiFi sources are allowed, because blade control
    must have local-level latency for safety.
    """

    enabled: bool = False
    """True = blade on, False = blade off."""

    source: CommandSource = CommandSource.BLE
    timestamp_ms: int = 0

    def __post_init__(self) -> None:
        if self.timestamp_ms == 0:
            self.timestamp_ms = int(time.time() * 1000)

    @classmethod
    def from_ble_byte(cls, value: int) -> "BladeCommand":
        """Parse from single BLE byte: 0x01=on, 0x00=off."""
        return cls(enabled=bool(value), source=CommandSource.BLE)

    def is_safe_source(self) -> bool:
        """Check if the command source is acceptable for blade control.

        Blade commands via cloud are rejected for safety.
        """
        return self.source in (CommandSource.BLE, CommandSource.WEBSOCKET)


@dataclass
class EStopCommand:
    """Emergency stop command.

    The highest-priority command. Sent on ALL channels simultaneously.
    When received from any channel, the robot immediately:
    1. Stops all motors via hardware interrupt
    2. Disengages blade via relay
    3. Sets state to 'estop'
    4. Rejects all commands except estop_clear
    5. Sets LED to red rapid flash (state 10)

    E-Stop clear requires a confirmation code and self-diagnostics pass.
    """

    activate: bool = True
    """True = activate E-Stop, False = clear E-Stop."""

    confirmation_code: Optional[str] = None
    """Required when clearing E-Stop. Must equal ESTOP_CLEAR_CONFIRMATION."""

    source: CommandSource = CommandSource.BLE
    timestamp_ms: int = 0

    def __post_init__(self) -> None:
        if self.timestamp_ms == 0:
            self.timestamp_ms = int(time.time() * 1000)

    @classmethod
    def from_ble_byte(cls, value: int) -> "EStopCommand":
        """Parse from single BLE byte: 0x01=activate, 0x00=clear."""
        return cls(activate=bool(value), source=CommandSource.BLE)

    @classmethod
    def from_websocket_dict(cls, payload: Dict[str, Any]) -> "EStopCommand":
        """Parse from WebSocket estop/estop_clear message."""
        return cls(
            activate=payload.get("action", "activate") == "activate",
            confirmation_code=payload.get("confirmation_code"),
            source=CommandSource.WEBSOCKET,
        )

    def validate_clear(self) -> bool:
        """Validate that the E-Stop clear has the correct confirmation code."""
        from ..config import ESTOP_CLEAR_CONFIRMATION

        if self.activate:
            return True  # Activation does not need confirmation
        return self.confirmation_code == ESTOP_CLEAR_CONFIRMATION


@dataclass
class DockCommand:
    """Command to return the robot to its charging dock.

    The robot uses its navigation stack (nav2) to autonomously navigate
    back to the configured dock location.
    """

    command_id: str = ""
    source: CommandSource = CommandSource.WEBSOCKET
    timestamp_ms: int = 0

    def __post_init__(self) -> None:
        if not self.command_id:
            self.command_id = str(uuid.uuid4())
        if self.timestamp_ms == 0:
            self.timestamp_ms = int(time.time() * 1000)
