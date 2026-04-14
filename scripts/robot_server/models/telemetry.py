"""
Telemetry data models.

These dataclasses represent the robot's sensor data as collected from ROS2
topics and aggregated for transmission to the Flutter app via BLE, WebSocket,
and Firebase.

Packed byte formats are defined for BLE characteristics where JSON overhead
is unacceptable (10Hz+ streaming). See config.py for byte layout documentation.
"""

from dataclasses import dataclass, field
from typing import Optional, Dict, Any, List
import struct
import time
import json


@dataclass
class BatteryTelemetry:
    """Battery state from the battery management system (BMS).

    Source: ROS2 topic /battery/state (sensor_msgs/BatteryState)
    Update rate: 1 Hz
    """

    percent: float = 0.0
    """Battery state of charge as percentage (0.0 to 100.0)."""

    voltage: float = 0.0
    """Battery terminal voltage in volts (e.g., 25.4V for a 24V pack)."""

    current_amps: float = 0.0
    """Current draw in amperes. Negative values indicate charging."""

    temp_c: float = 0.0
    """Battery pack temperature in degrees Celsius."""

    health_pct: float = 100.0
    """Battery state of health as percentage (0-100). Decreases over cycle life."""

    cycles: int = 0
    """Total charge/discharge cycle count."""

    def to_dict(self) -> Dict[str, Any]:
        """Serialize to dict for JSON/WebSocket transmission."""
        return {
            "percent": round(self.percent, 1),
            "voltage": round(self.voltage, 2),
            "current_amps": round(self.current_amps, 2),
            "temp_c": round(self.temp_c, 1),
            "health_pct": round(self.health_pct, 0),
            "cycles": self.cycles,
        }

    def pack_core_bytes(self) -> bytes:
        """Pack battery fields into the core telemetry BLE characteristic.

        Returns bytes for inclusion in the 20-byte core telemetry packet:
            Bytes 0-1:  battery_pct (uint16, value * 100)
            Bytes 2-3:  battery_voltage (uint16, millivolts)
            Bytes 14-15: battery_current (int16, milliamps)
            Bytes 16-17: battery_temp (int16, centi-degrees C)
            Byte 18:    battery_health (uint8, 0-100)
            Byte 19:    battery_cycles high byte (uint8)
        """
        pct_packed = int(self.percent * 100)
        mv = int(self.voltage * 1000)
        ma = int(self.current_amps * 1000)
        temp_centi = int(self.temp_c * 100)
        health = int(self.health_pct)
        cycles_hi = (self.cycles >> 8) & 0xFF

        return struct.pack(
            "<HHhh BB",
            pct_packed, mv, ma, temp_centi, health, cycles_hi
        )


@dataclass
class MotionTelemetry:
    """Motion state derived from odometry and IMU.

    Source: ROS2 topics /odom (nav_msgs/Odometry) and /imu/data (sensor_msgs/Imu)
    Update rate: 10 Hz from odometry, 50 Hz from IMU (decimated to 10 Hz)
    """

    speed_ms: float = 0.0
    """Ground speed in meters per second. Always >= 0."""

    heading_deg: float = 0.0
    """Compass heading in degrees (0-359.99). 0 = North, 90 = East."""

    def to_dict(self) -> Dict[str, Any]:
        """Serialize to dict for JSON/WebSocket transmission."""
        return {
            "speed_ms": round(self.speed_ms, 3),
            "heading_deg": round(self.heading_deg, 1),
        }

    def pack_bytes(self) -> bytes:
        """Pack into BLE core telemetry bytes.

        Bytes 4-5: speed_ms (int16, mm/s)
        Bytes 6-7: heading_deg (uint16, centi-degrees)
        """
        speed_mms = int(self.speed_ms * 1000)
        heading_centi = int(self.heading_deg * 100)
        return struct.pack("<hH", speed_mms, heading_centi)


@dataclass
class GpsTelemetry:
    """GPS/GNSS position data with RTK quality indicators.

    Source: ROS2 topics /gps/fix (NavSatFix) and /gps/rtk_status (String)
    Update rate: 5 Hz for position, 1 Hz for RTK status
    """

    latitude: float = 0.0
    """Latitude in decimal degrees (WGS84). Positive = North."""

    longitude: float = 0.0
    """Longitude in decimal degrees (WGS84). Positive = East."""

    rtk_status: str = "none"
    """RTK fix quality: 'none', 'single', 'float', 'fix'."""

    satellite_count: int = 0
    """Number of satellites used in position solution."""

    accuracy_cm: float = 0.0
    """Horizontal position accuracy in centimeters."""

    def to_dict(self) -> Dict[str, Any]:
        """Serialize to dict for JSON/WebSocket transmission."""
        return {
            "latitude": self.latitude,
            "longitude": self.longitude,
            "rtk_status": self.rtk_status,
            "satellite_count": self.satellite_count,
            "accuracy_cm": round(self.accuracy_cm, 1),
        }

    def pack_bytes(self) -> bytes:
        """Pack into 12-byte BLE GPS characteristic.

        Bytes 0-3:  latitude (int32, microdegrees)
        Bytes 4-7:  longitude (int32, microdegrees)
        Bytes 8-9:  accuracy_cm (uint16)
        Bytes 10-11: reserved
        """
        lat_micro = int(self.latitude * 1_000_000)
        lng_micro = int(self.longitude * 1_000_000)
        acc = int(self.accuracy_cm)
        return struct.pack("<iiHH", lat_micro, lng_micro, acc, 0)


@dataclass
class MotorTelemetry:
    """Individual motor speed readings for the four drive motors.

    Source: ROS2 topic /motor_speeds (chorerobot_msgs/MotorSpeeds)
    Update rate: 10 Hz
    """

    fl_rpm: int = 0
    """Front-left motor speed in RPM. Negative = reverse."""

    fr_rpm: int = 0
    """Front-right motor speed in RPM. Negative = reverse."""

    rl_rpm: int = 0
    """Rear-left motor speed in RPM. Negative = reverse."""

    rr_rpm: int = 0
    """Rear-right motor speed in RPM. Negative = reverse."""

    def to_dict(self) -> Dict[str, Any]:
        """Serialize to dict for JSON/WebSocket transmission."""
        return {
            "fl_rpm": self.fl_rpm,
            "fr_rpm": self.fr_rpm,
            "rl_rpm": self.rl_rpm,
            "rr_rpm": self.rr_rpm,
        }

    def pack_bytes(self) -> bytes:
        """Pack into 8-byte BLE motor speeds characteristic.

        Bytes 0-1: fl_rpm (int16)
        Bytes 2-3: fr_rpm (int16)
        Bytes 4-5: rl_rpm (int16)
        Bytes 6-7: rr_rpm (int16)
        """
        return struct.pack(
            "<hhhh", self.fl_rpm, self.fr_rpm, self.rl_rpm, self.rr_rpm
        )


@dataclass
class SystemTelemetry:
    """System-level state information.

    Aggregated from various ROS2 topics and internal state.
    """

    temp_c: float = 0.0
    """Jetson Nano board temperature in degrees Celsius."""

    state: str = "idle"
    """Robot operational state. One of: idle, working, charging, paused, error, estop, docked."""

    active_task_id: Optional[str] = None
    """ID of the currently active task, or None if no task is running."""

    signal_strength: int = 0
    """Signal quality indicator (0-4 bars). Computed from BLE RSSI or WiFi signal."""

    attachment_type: str = "none"
    """Currently connected attachment: 'mower_blade', 'snow_plow', 'leaf_collector', 'none'."""

    def to_dict(self) -> Dict[str, Any]:
        """Serialize to dict for JSON/WebSocket transmission."""
        return {
            "temp_c": round(self.temp_c, 1),
            "state": self.state,
            "active_task_id": self.active_task_id,
            "signal_strength": self.signal_strength,
            "attachment_type": self.attachment_type,
        }


@dataclass
class TelemetrySnapshot:
    """Complete telemetry state at a single point in time.

    This is the unified telemetry model that combines all sensor data.
    It is the source of truth for all outgoing telemetry on every channel
    (BLE, WebSocket, Firebase).

    Updated by the ROS2 bridge at varying rates per subsystem. The snapshot
    itself is read by the BLE, WebSocket, and Firebase modules at their
    respective output rates.
    """

    battery: BatteryTelemetry = field(default_factory=BatteryTelemetry)
    motion: MotionTelemetry = field(default_factory=MotionTelemetry)
    gps: GpsTelemetry = field(default_factory=GpsTelemetry)
    motors: MotorTelemetry = field(default_factory=MotorTelemetry)
    system: SystemTelemetry = field(default_factory=SystemTelemetry)
    timestamp_ms: int = 0
    """Unix timestamp in milliseconds when this snapshot was captured."""

    def __post_init__(self) -> None:
        if self.timestamp_ms == 0:
            self.timestamp_ms = int(time.time() * 1000)

    def to_dict(self) -> Dict[str, Any]:
        """Serialize to full JSON dict for WebSocket telemetry message payload."""
        return {
            "battery": self.battery.to_dict(),
            "motion": {
                "speed_ms": round(self.motion.speed_ms, 3),
                "heading_deg": round(self.motion.heading_deg, 1),
                "latitude": self.gps.latitude,
                "longitude": self.gps.longitude,
            },
            "gps": self.gps.to_dict(),
            "motors": self.motors.to_dict(),
            "system": self.system.to_dict(),
        }

    def to_rtdb_dict(self) -> Dict[str, Any]:
        """Serialize to flat dict for Firebase Realtime Database.

        The RTDB uses a flat key structure (not nested) so the app can
        listen to individual fields without downloading the entire object.
        """
        return {
            "battery_pct": round(self.battery.percent, 1),
            "battery_voltage": round(self.battery.voltage, 2),
            "battery_current_amps": round(self.battery.current_amps, 2),
            "battery_temp_c": round(self.battery.temp_c, 1),
            "battery_health_pct": round(self.battery.health_pct, 0),
            "battery_cycles": self.battery.cycles,
            "speed_ms": round(self.motion.speed_ms, 3),
            "heading_deg": round(self.motion.heading_deg, 1),
            "latitude": self.gps.latitude,
            "longitude": self.gps.longitude,
            "rtk_status": self.gps.rtk_status,
            "satellite_count": self.gps.satellite_count,
            "position_accuracy_cm": round(self.gps.accuracy_cm, 1),
            "motor_fl_rpm": self.motors.fl_rpm,
            "motor_fr_rpm": self.motors.fr_rpm,
            "motor_rl_rpm": self.motors.rl_rpm,
            "motor_rr_rpm": self.motors.rr_rpm,
            "system_temp_c": round(self.system.temp_c, 1),
            "state": self.system.state,
            "active_task_id": self.system.active_task_id,
            "signal_strength": self.system.signal_strength,
            "attachment_type": self.system.attachment_type,
            "timestamp": self.timestamp_ms,
        }

    def to_firestore_dict(self) -> Dict[str, Any]:
        """Serialize to dict for Firestore telemetry_snapshots document."""
        return {
            "batteryPct": round(self.battery.percent, 1),
            "batteryVoltage": round(self.battery.voltage, 2),
            "batteryCurrentAmps": round(self.battery.current_amps, 2),
            "batteryTempC": round(self.battery.temp_c, 1),
            "latitude": self.gps.latitude,
            "longitude": self.gps.longitude,
            "headingDeg": round(self.motion.heading_deg, 1),
            "speedMs": round(self.motion.speed_ms, 3),
            "rtkStatus": self.gps.rtk_status,
            "satelliteCount": self.gps.satellite_count,
            "positionAccuracyCm": round(self.gps.accuracy_cm, 1),
            "motors": self.motors.to_dict(),
            "systemTempC": round(self.system.temp_c, 1),
            "state": self.system.state,
            "activeTaskId": self.system.active_task_id,
            "signalStrength": self.system.signal_strength,
        }

    def pack_core_ble(self) -> bytes:
        """Pack into 20-byte BLE core telemetry characteristic.

        Layout (little-endian):
            Bytes  0-1:  battery_pct (uint16, value * 100)
            Bytes  2-3:  battery_voltage (uint16, millivolts)
            Bytes  4-5:  speed_ms (int16, mm/s)
            Bytes  6-7:  heading_deg (uint16, centi-degrees)
            Byte   8:    state (uint8, enum)
            Byte   9:    signal_strength (uint8, 0-4)
            Byte  10:    rtk_status (uint8, enum)
            Byte  11:    satellite_count (uint8)
            Bytes 12-13: system_temp (int16, centi-degrees)
            Bytes 14-15: battery_current (int16, milliamps)
            Bytes 16-17: battery_temp (int16, centi-degrees)
            Byte  18:    battery_health (uint8, 0-100)
            Byte  19:    battery_cycles high byte (uint8)
        """
        from ..config import ROBOT_STATE_TO_BYTE, RTK_STATUS_TO_BYTE

        return struct.pack(
            "<HH hH BB BB hh hh BB",
            int(self.battery.percent * 100),        # 0-1
            int(self.battery.voltage * 1000),        # 2-3
            int(self.motion.speed_ms * 1000),        # 4-5
            int(self.motion.heading_deg * 100),      # 6-7
            ROBOT_STATE_TO_BYTE.get(self.system.state, 0),  # 8
            self.system.signal_strength,             # 9
            RTK_STATUS_TO_BYTE.get(self.gps.rtk_status, 0),  # 10
            self.gps.satellite_count,                # 11
            int(self.system.temp_c * 100),           # 12-13
            int(self.battery.current_amps * 1000),   # 14-15
            int(self.battery.temp_c * 100),          # 16-17
            int(self.battery.health_pct),            # 18
            (self.battery.cycles >> 8) & 0xFF,       # 19
        )

    def to_json(self) -> str:
        """Serialize to JSON string for BLE extended telemetry characteristic."""
        return json.dumps(self.to_dict())
