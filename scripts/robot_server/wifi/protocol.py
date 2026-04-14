"""
WebSocket Message Protocol.

Defines the JSON message format for WebSocket communication between the
Flutter app and the robot server. All messages have a common envelope
with type, id, timestamp, and payload fields.

Message Direction:
    App -> Robot: drive_command, task_start, task_stop, task_pause,
                  task_resume, estop, estop_clear, dock, blade_control,
                  zone_sync, schedule_sync, ping
    Robot -> App: telemetry, task_update, command_ack, alert,
                  estop_status, pong, wifi_scan_result
"""

import json
import uuid
import time
import logging
from typing import Dict, Any, Optional

from ..config import (
    MSG_TYPE_DRIVE_COMMAND,
    MSG_TYPE_TASK_START,
    MSG_TYPE_TASK_STOP,
    MSG_TYPE_TASK_PAUSE,
    MSG_TYPE_TASK_RESUME,
    MSG_TYPE_ESTOP,
    MSG_TYPE_ESTOP_CLEAR,
    MSG_TYPE_DOCK,
    MSG_TYPE_BLADE_CONTROL,
    MSG_TYPE_ZONE_SYNC,
    MSG_TYPE_SCHEDULE_SYNC,
    MSG_TYPE_PING,
    MSG_TYPE_TELEMETRY,
    MSG_TYPE_TASK_UPDATE,
    MSG_TYPE_COMMAND_ACK,
    MSG_TYPE_ALERT,
    MSG_TYPE_ESTOP_STATUS,
    MSG_TYPE_PONG,
    MSG_TYPE_WIFI_SCAN_RESULT,
)

logger = logging.getLogger(__name__)

# Set of valid incoming message types (app -> robot)
VALID_INCOMING_TYPES = frozenset({
    MSG_TYPE_DRIVE_COMMAND,
    MSG_TYPE_TASK_START,
    MSG_TYPE_TASK_STOP,
    MSG_TYPE_TASK_PAUSE,
    MSG_TYPE_TASK_RESUME,
    MSG_TYPE_ESTOP,
    MSG_TYPE_ESTOP_CLEAR,
    MSG_TYPE_DOCK,
    MSG_TYPE_BLADE_CONTROL,
    MSG_TYPE_ZONE_SYNC,
    MSG_TYPE_SCHEDULE_SYNC,
    MSG_TYPE_PING,
})


class MessageProtocol:
    """Serialization and deserialization for WebSocket JSON messages.

    All messages follow the envelope format:
    {
        "type": "<message_type>",
        "id": "<uuid>",
        "timestamp": <unix_ms>,
        "payload": { ... }
    }

    Usage:
        # Parsing incoming
        msg = MessageProtocol.parse(raw_text)
        if msg:
            msg_type = msg["type"]
            payload = msg["payload"]

        # Building outgoing
        raw = MessageProtocol.build_telemetry(telemetry_dict)
        await ws.send(raw)
    """

    @staticmethod
    def parse(raw: str) -> Optional[Dict[str, Any]]:
        """Parse a raw WebSocket text frame into a message dict.

        Validates the message structure (type, id, timestamp, payload).
        Returns None if the message is malformed.

        Args:
            raw: Raw JSON string from WebSocket text frame.

        Returns:
            Parsed message dict, or None if invalid.
        """
        try:
            msg = json.loads(raw)
        except json.JSONDecodeError as e:
            logger.warning(f"Invalid JSON from WebSocket: {e}")
            return None

        if not isinstance(msg, dict):
            logger.warning("WebSocket message is not a JSON object")
            return None

        msg_type = msg.get("type")
        if not msg_type or msg_type not in VALID_INCOMING_TYPES:
            logger.warning(f"Unknown or missing message type: {msg_type}")
            return None

        # Ensure required fields
        if "id" not in msg:
            msg["id"] = str(uuid.uuid4())
        if "timestamp" not in msg:
            msg["timestamp"] = int(time.time() * 1000)
        if "payload" not in msg:
            msg["payload"] = {}

        return msg

    @staticmethod
    def build(msg_type: str, payload: Dict[str, Any]) -> str:
        """Build a JSON message string with the standard envelope.

        Args:
            msg_type: Message type string (e.g., "telemetry").
            payload: Message payload dict.

        Returns:
            JSON string ready to send via WebSocket.
        """
        msg = {
            "type": msg_type,
            "id": str(uuid.uuid4()),
            "timestamp": int(time.time() * 1000),
            "payload": payload,
        }
        return json.dumps(msg, separators=(",", ":"))  # compact JSON

    @staticmethod
    def build_telemetry(telemetry_dict: Dict[str, Any]) -> str:
        """Build a telemetry message.

        Args:
            telemetry_dict: Output of TelemetrySnapshot.to_dict().

        Returns:
            JSON string for the telemetry WebSocket message.
        """
        return MessageProtocol.build(MSG_TYPE_TELEMETRY, telemetry_dict)

    @staticmethod
    def build_task_update(task_dict: Dict[str, Any]) -> str:
        """Build a task progress update message.

        Args:
            task_dict: Output of TaskState.to_websocket_dict().

        Returns:
            JSON string for the task_update WebSocket message.
        """
        return MessageProtocol.build(MSG_TYPE_TASK_UPDATE, task_dict)

    @staticmethod
    def build_command_ack(
        command_id: str,
        status: str,
        message: Optional[str] = None,
    ) -> str:
        """Build a command acknowledgement message.

        Args:
            command_id: ID of the command being acknowledged.
            status: Acknowledgement status: 'accepted', 'rejected', 'error'.
            message: Optional human-readable message.

        Returns:
            JSON string for the command_ack WebSocket message.
        """
        payload = {
            "command_id": command_id,
            "status": status,
            "message": message,
        }
        return MessageProtocol.build(MSG_TYPE_COMMAND_ACK, payload)

    @staticmethod
    def build_alert(alert_dict: Dict[str, Any]) -> str:
        """Build a diagnostic alert message.

        Args:
            alert_dict: Output of AlertEntry.to_websocket_dict().

        Returns:
            JSON string for the alert WebSocket message.
        """
        return MessageProtocol.build(MSG_TYPE_ALERT, alert_dict)

    @staticmethod
    def build_estop_status(
        active: bool,
        source: str,
        triggered_at: int,
    ) -> str:
        """Build an E-Stop status change message.

        Args:
            active: Whether E-Stop is currently active.
            source: Source that triggered/cleared the E-Stop.
            triggered_at: Unix ms when E-Stop was triggered.

        Returns:
            JSON string for the estop_status WebSocket message.
        """
        payload = {
            "active": active,
            "source": source,
            "triggered_at": triggered_at,
        }
        return MessageProtocol.build(MSG_TYPE_ESTOP_STATUS, payload)

    @staticmethod
    def build_pong(ping_id: str) -> str:
        """Build a pong response to a ping.

        Args:
            ping_id: Message ID of the ping being responded to.

        Returns:
            JSON string for the pong WebSocket message.
        """
        return MessageProtocol.build(MSG_TYPE_PONG, {"ping_id": ping_id})

    @staticmethod
    def build_wifi_scan_result(networks: list) -> str:
        """Build a WiFi scan result message.

        Args:
            networks: List of dicts with ssid, signal_strength, security, channel.

        Returns:
            JSON string for the wifi_scan_result WebSocket message.
        """
        return MessageProtocol.build(MSG_TYPE_WIFI_SCAN_RESULT, {"networks": networks})
