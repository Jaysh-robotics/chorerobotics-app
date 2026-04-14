"""
Configuration constants for the ChoreRobotics Robot Server.

All UUIDs, ports, GPIO pins, topic names, and tuning parameters are
defined here as a single source of truth. Import from this module
instead of hardcoding values elsewhere.

UUID Convention:
    All BLE UUIDs use the ChoreRobotics base: C40EXXXX-0001-1000-8000-00805F9B34FB
    Service UUIDs use C40E000X pattern.
    Characteristic UUIDs use C40E0XYY where X=service number, YY=characteristic index.
"""

from dataclasses import dataclass, field
from typing import Dict, List
import os


# =============================================================================
# ROBOT IDENTITY
# =============================================================================

# Read from device config file provisioned during manufacturing
ROBOT_SERIAL: str = os.environ.get("C40EEROBOT_SERIAL", "CR-MK1-00001")
ROBOT_MODEL: str = os.environ.get("C40EEROBOT_MODEL", "C40EEROBOT-MK1")
ROBOT_FIRMWARE_VERSION: str = os.environ.get("C40EEROBOT_FIRMWARE", "1.0.0")

# Default robot name (user can rename via BLE or Firestore)
DEFAULT_ROBOT_NAME: str = "My ChoreBot"

# Identity config file path (written during manufacturing)
IDENTITY_CONFIG_PATH: str = "/etc/chorerobot/identity.json"


# =============================================================================
# BLE CONFIGURATION
# =============================================================================

# Base UUID template: replace XXXX with service/characteristic code
BLE_BASE_UUID: str = "C40E{code}-0001-1000-8000-00805F9B34FB"

# Device advertising name prefix (full name = prefix + last 4 of serial)
BLE_DEVICE_NAME_PREFIX: str = "ChoreBot-"
BLE_ADVERTISING_INTERVAL_MS: int = 100

# Pairing
BLE_PAIRING_CODE_LENGTH: int = 6
BLE_PAIRING_TOKEN_LENGTH: int = 32  # hex characters (16 bytes)
BLE_PAIRING_TIMEOUT_S: int = 120  # Return to discoverable after 2 min inactivity

# --- Service UUIDs ---
BLE_SERVICE_ROBOT_INFO: str = "C40E0001-0001-1000-8000-00805F9B34FB"
BLE_SERVICE_PAIRING: str = "C40E0002-0001-1000-8000-00805F9B34FB"
BLE_SERVICE_COMMAND: str = "C40E0003-0001-1000-8000-00805F9B34FB"
BLE_SERVICE_TELEMETRY: str = "C40E0004-0001-1000-8000-00805F9B34FB"
BLE_SERVICE_WIFI_CONFIG: str = "C40E0005-0001-1000-8000-00805F9B34FB"

# --- Robot Info Characteristics ---
BLE_CHAR_SERIAL_NUMBER: str = "C40E0101-0001-1000-8000-00805F9B34FB"
BLE_CHAR_MODEL: str = "C40E0102-0001-1000-8000-00805F9B34FB"
BLE_CHAR_FIRMWARE_VERSION: str = "C40E0103-0001-1000-8000-00805F9B34FB"
BLE_CHAR_ROBOT_NAME: str = "C40E0104-0001-1000-8000-00805F9B34FB"
BLE_CHAR_ATTACHMENT_TYPE: str = "C40E0105-0001-1000-8000-00805F9B34FB"

# --- Pairing Characteristics ---
BLE_CHAR_PAIRING_STATE: str = "C40E0201-0001-1000-8000-00805F9B34FB"
BLE_CHAR_PAIRING_CODE: str = "C40E0202-0001-1000-8000-00805F9B34FB"
BLE_CHAR_PAIRING_RESULT: str = "C40E0203-0001-1000-8000-00805F9B34FB"
BLE_CHAR_PAIRING_TOKEN: str = "C40E0204-0001-1000-8000-00805F9B34FB"

# --- Command Characteristics ---
BLE_CHAR_DRIVE_COMMAND: str = "C40E0301-0001-1000-8000-00805F9B34FB"
BLE_CHAR_TASK_COMMAND: str = "C40E0302-0001-1000-8000-00805F9B34FB"
BLE_CHAR_ESTOP: str = "C40E0303-0001-1000-8000-00805F9B34FB"
BLE_CHAR_COMMAND_ACK: str = "C40E0304-0001-1000-8000-00805F9B34FB"
BLE_CHAR_BLADE_CONTROL: str = "C40E0305-0001-1000-8000-00805F9B34FB"

# --- Telemetry Characteristics ---
BLE_CHAR_CORE_TELEMETRY: str = "C40E0401-0001-1000-8000-00805F9B34FB"
BLE_CHAR_GPS_POSITION: str = "C40E0402-0001-1000-8000-00805F9B34FB"
BLE_CHAR_MOTOR_SPEEDS: str = "C40E0403-0001-1000-8000-00805F9B34FB"
BLE_CHAR_EXTENDED_TELEMETRY: str = "C40E0404-0001-1000-8000-00805F9B34FB"
BLE_CHAR_DIAGNOSTICS: str = "C40E0405-0001-1000-8000-00805F9B34FB"
BLE_CHAR_TASK_PROGRESS: str = "C40E0406-0001-1000-8000-00805F9B34FB"

# --- WiFi Config Characteristics ---
BLE_CHAR_WIFI_SCAN: str = "C40E0501-0001-1000-8000-00805F9B34FB"
BLE_CHAR_WIFI_CREDENTIALS: str = "C40E0502-0001-1000-8000-00805F9B34FB"
BLE_CHAR_WIFI_STATUS: str = "C40E0503-0001-1000-8000-00805F9B34FB"
BLE_CHAR_WIFI_IP_ADDRESS: str = "C40E0504-0001-1000-8000-00805F9B34FB"


# =============================================================================
# WEBSOCKET CONFIGURATION
# =============================================================================

WEBSOCKET_HOST: str = "0.0.0.0"
WEBSOCKET_PORT: int = 8765
WEBSOCKET_PATH: str = "/ws"
WEBSOCKET_HEARTBEAT_INTERVAL_S: int = 5
WEBSOCKET_HEARTBEAT_TIMEOUT_S: int = 15  # 3 missed pings
WEBSOCKET_MAX_MESSAGE_SIZE_BYTES: int = 65536
WEBSOCKET_MAX_CONNECTIONS: int = 3  # max simultaneous app connections

# mDNS service name pattern: chorerobot-XXXX.local
MDNS_SERVICE_TYPE: str = "_chorerobot._tcp"
MDNS_SERVICE_PORT: int = WEBSOCKET_PORT


# =============================================================================
# FIREBASE CONFIGURATION
# =============================================================================

FIREBASE_SERVICE_ACCOUNT_PATH: str = "/etc/chorerobot/firebase-service-account.json"
FIREBASE_DATABASE_URL: str = "https://chorerobotics-app-default-rtdb.firebaseio.com"
FIREBASE_STORAGE_BUCKET: str = "chorerobotics-app.firebasestorage.app"

# Upload intervals
FIREBASE_TELEMETRY_UPLOAD_INTERVAL_S: float = 5.0
FIREBASE_SNAPSHOT_INTERVAL_S: float = 60.0
FIREBASE_SNAPSHOT_IDLE_INTERVAL_S: float = 300.0
FIREBASE_HEARTBEAT_INTERVAL_S: float = 30.0
FIREBASE_COMMAND_POLL_INTERVAL_S: float = 5.0  # fallback if listener fails
FIREBASE_FIRMWARE_CHECK_INTERVAL_S: float = 21600.0  # 6 hours

# Firestore collection paths
FIRESTORE_USERS_COLLECTION: str = "users"
FIRESTORE_ROBOTS_COLLECTION: str = "robots"
FIRESTORE_FIRMWARE_COLLECTION: str = "firmware"
FIRESTORE_APP_CONFIG_COLLECTION: str = "app_config"

# Realtime Database paths
RTDB_TELEMETRY_PATH: str = "robots/{robot_id}/telemetry"
RTDB_ROBOT_STATUS_PATH: str = "robot_status/{robot_id}"
RTDB_ROBOT_OWNERS_PATH: str = "_robot_owners/{robot_id}"


# =============================================================================
# TELEMETRY RATES (Hz)
# =============================================================================

TELEMETRY_BLE_CORE_HZ: float = 10.0
TELEMETRY_BLE_GPS_HZ: float = 5.0
TELEMETRY_BLE_MOTOR_HZ: float = 5.0
TELEMETRY_BLE_EXTENDED_HZ: float = 1.0
TELEMETRY_WIFI_HZ: float = 10.0
TELEMETRY_CLOUD_HZ: float = 0.2
TELEMETRY_TASK_PROGRESS_HZ: float = 1.0
TELEMETRY_DIAGNOSTICS_HZ: float = 1.0


# =============================================================================
# SAFETY CONFIGURATION
# =============================================================================

ESTOP_CLEAR_CONFIRMATION: str = "CLEAR-ESTOP"
CONNECTION_LOSS_CONTINUE_S: int = 10
CONNECTION_LOSS_PAUSE_S: int = 20
CONNECTION_LOSS_DOCK_S: int = 30
CONNECTION_LOSS_ESTOP_S: int = 30  # estop if dock also fails
MIN_BATTERY_FOR_TASK_PCT: int = 20
MIN_BATTERY_FOR_FIRMWARE_PCT: int = 50
MAX_TILT_ANGLE_DEG: float = 30.0
WATCHDOG_TIMEOUT_S: int = 60


# =============================================================================
# LED CONFIGURATION
# =============================================================================

LED_COUNT: int = 12
LED_GPIO_PIN: int = 18  # PWM0 on Jetson Nano
LED_BRIGHTNESS: int = 128  # 0-255
LED_FREQ_HZ: int = 800000  # WS2812B signal frequency
LED_DMA_CHANNEL: int = 10
LED_INVERT: bool = False

# LED colors (R, G, B)
LED_COLOR_WHITE: tuple = (255, 255, 255)
LED_COLOR_GREEN: tuple = (0, 255, 0)
LED_COLOR_RED: tuple = (255, 0, 0)
LED_COLOR_OFF: tuple = (0, 0, 0)


# =============================================================================
# ROS2 CONFIGURATION
# =============================================================================

ROS2_NODE_NAME: str = "chorerobot_server"
ROS2_NAMESPACE: str = ""

# Quality of Service
ROS2_QOS_RELIABLE_DEPTH: int = 10
ROS2_QOS_BEST_EFFORT_DEPTH: int = 10

# --- Subscribed Topics (robot sensors -> server) ---
ROS2_TOPIC_BATTERY_STATE: str = "/battery/state"
ROS2_TOPIC_ODOMETRY: str = "/odom"
ROS2_TOPIC_IMU: str = "/imu/data"
ROS2_TOPIC_GPS_FIX: str = "/gps/fix"
ROS2_TOPIC_RTK_STATUS: str = "/gps/rtk_status"
ROS2_TOPIC_MOTOR_SPEEDS: str = "/motor_speeds"
ROS2_TOPIC_SYSTEM_TEMP: str = "/system/temperature"
ROS2_TOPIC_ATTACHMENT_STATE: str = "/attachment/state"
ROS2_TOPIC_TASK_PROGRESS: str = "/task/progress"
ROS2_TOPIC_DIAGNOSTICS: str = "/diagnostics"
ROS2_TOPIC_ESTOP_STATE: str = "/estop/state"

# --- Published Topics (server -> robot actuators) ---
ROS2_TOPIC_CMD_VEL: str = "/cmd_vel"
ROS2_TOPIC_TASK_START: str = "/task/start"
ROS2_TOPIC_TASK_STOP: str = "/task/stop"
ROS2_TOPIC_TASK_PAUSE: str = "/task/pause"
ROS2_TOPIC_TASK_RESUME: str = "/task/resume"
ROS2_TOPIC_ESTOP_COMMAND: str = "/estop/command"
ROS2_TOPIC_BLADE_COMMAND: str = "/blade/command"
ROS2_TOPIC_DOCK_COMMAND: str = "/dock/command"
ROS2_TOPIC_ZONES_UPDATE: str = "/zones/update"
ROS2_TOPIC_SCHEDULES_UPDATE: str = "/schedules/update"


# =============================================================================
# WEBSOCKET MESSAGE TYPES
# =============================================================================

# App -> Robot
MSG_TYPE_DRIVE_COMMAND: str = "drive_command"
MSG_TYPE_TASK_START: str = "task_start"
MSG_TYPE_TASK_STOP: str = "task_stop"
MSG_TYPE_TASK_PAUSE: str = "task_pause"
MSG_TYPE_TASK_RESUME: str = "task_resume"
MSG_TYPE_ESTOP: str = "estop"
MSG_TYPE_ESTOP_CLEAR: str = "estop_clear"
MSG_TYPE_DOCK: str = "dock"
MSG_TYPE_BLADE_CONTROL: str = "blade_control"
MSG_TYPE_ZONE_SYNC: str = "zone_sync"
MSG_TYPE_SCHEDULE_SYNC: str = "schedule_sync"
MSG_TYPE_PING: str = "ping"

# Robot -> App
MSG_TYPE_TELEMETRY: str = "telemetry"
MSG_TYPE_TASK_UPDATE: str = "task_update"
MSG_TYPE_COMMAND_ACK: str = "command_ack"
MSG_TYPE_ALERT: str = "alert"
MSG_TYPE_ESTOP_STATUS: str = "estop_status"
MSG_TYPE_PONG: str = "pong"
MSG_TYPE_WIFI_SCAN_RESULT: str = "wifi_scan_result"


# =============================================================================
# PAIRING STATE ENUM VALUES
# =============================================================================

PAIRING_STATE_DISCOVERABLE: int = 0
PAIRING_STATE_FOUND: int = 1
PAIRING_STATE_PAIRING: int = 2
PAIRING_STATE_AWAITING_CODE: int = 3
PAIRING_STATE_VERIFYING: int = 4
PAIRING_STATE_SUCCESS: int = 5
PAIRING_STATE_WIFI_SETUP: int = 6
PAIRING_STATE_COMPLETE: int = 7
PAIRING_STATE_FAILED: int = 8

# Pairing result values
PAIRING_RESULT_PENDING: int = 0
PAIRING_RESULT_SUCCESS: int = 1
PAIRING_RESULT_FAILED: int = 2

# WiFi status values
WIFI_STATUS_DISCONNECTED: int = 0
WIFI_STATUS_CONNECTING: int = 1
WIFI_STATUS_CONNECTED: int = 2
WIFI_STATUS_FAILED: int = 3


# =============================================================================
# LED STATE ENUM VALUES (matches led_pairing_spec.md)
# =============================================================================

LED_STATE_OFF: int = 0
LED_STATE_DISCOVERABLE: int = 1
LED_STATE_FOUND: int = 2
LED_STATE_PAIRING: int = 3
LED_STATE_AWAITING_CODE: int = 4
LED_STATE_VERIFYING: int = 5
LED_STATE_SUCCESS: int = 6
LED_STATE_WIFI_SETUP: int = 7
LED_STATE_COMPLETE: int = 8
LED_STATE_FAILED: int = 9
LED_STATE_ESTOP: int = 10


# =============================================================================
# DRIVE COMMAND BYTE FORMAT
# =============================================================================

# BLE drive command is 4 bytes packed:
# Byte 0: linear_x  (int8, -127 to +127)
# Byte 1: linear_y  (int8, -127 to +127)
# Byte 2: angular_z (int8, -127 to +127)
# Byte 3: flags     (uint8, bitfield)
#          bit 0: blade_on
#          bit 1: turbo_mode
#          bits 2-7: reserved

DRIVE_CMD_FLAG_BLADE_ON: int = 0x01
DRIVE_CMD_FLAG_TURBO: int = 0x02


# =============================================================================
# ROBOT STATE ENUM VALUES
# =============================================================================

ROBOT_STATE_IDLE: str = "idle"
ROBOT_STATE_WORKING: str = "working"
ROBOT_STATE_CHARGING: str = "charging"
ROBOT_STATE_PAUSED: str = "paused"
ROBOT_STATE_ERROR: str = "error"
ROBOT_STATE_ESTOP: str = "estop"
ROBOT_STATE_DOCKED: str = "docked"

# State to uint8 mapping for BLE packed telemetry
ROBOT_STATE_TO_BYTE: Dict[str, int] = {
    "idle": 0,
    "working": 1,
    "charging": 2,
    "paused": 3,
    "error": 4,
    "estop": 5,
    "docked": 6,
}

ROBOT_BYTE_TO_STATE: Dict[int, str] = {v: k for k, v in ROBOT_STATE_TO_BYTE.items()}


# =============================================================================
# RTK STATUS ENUM VALUES
# =============================================================================

RTK_STATUS_NONE: str = "none"
RTK_STATUS_SINGLE: str = "single"
RTK_STATUS_FLOAT: str = "float"
RTK_STATUS_FIX: str = "fix"

RTK_STATUS_TO_BYTE: Dict[str, int] = {
    "none": 0,
    "single": 1,
    "float": 2,
    "fix": 3,
}

RTK_BYTE_TO_STATUS: Dict[int, str] = {v: k for k, v in RTK_STATUS_TO_BYTE.items()}


# =============================================================================
# ALERT SEVERITY AND CATEGORY
# =============================================================================

ALERT_SEVERITY_CRITICAL: str = "critical"
ALERT_SEVERITY_WARNING: str = "warning"
ALERT_SEVERITY_INFO: str = "info"

ALERT_CATEGORY_MOTOR: str = "motor"
ALERT_CATEGORY_BLADE: str = "blade"
ALERT_CATEGORY_BATTERY: str = "battery"
ALERT_CATEGORY_CONNECTION: str = "connection"
ALERT_CATEGORY_GPS: str = "gps"
ALERT_CATEGORY_SENSOR: str = "sensor"
ALERT_CATEGORY_SYSTEM: str = "system"
ALERT_CATEGORY_SAFETY: str = "safety"
