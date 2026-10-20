"""Robot-like WebSocket simulator for app integration.

This is the local replacement for the old echo-only server. It keeps the same
phone-friendly URL shape, but behaves closer to the robot server contract:

- accepts production message types such as task_start, task_pause, task_resume
- acknowledges every accepted command with command_ack
- logs ROS2-like topic publications for commands
- maintains fake robot/task state
- streams telemetry and task_update messages back to connected apps

Run from the repo root:
    python scripts/robot_server/simulated_robot_server.py
"""

from __future__ import annotations

import argparse
import asyncio
import json
import math
import os
import socket
import sys
import time
import uuid
from dataclasses import dataclass, field
from typing import Any

try:
    import websockets
    from websockets.exceptions import ConnectionClosed
except ImportError as exc:  # pragma: no cover - startup guidance
    raise SystemExit(
        "Missing dependency: websockets\n"
        "Install with: python -m pip install -r scripts/robot_server/requirements.txt"
    ) from exc

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(line_buffering=True)


VALID_MESSAGE_TYPES = {
    "ping",
    "drive_command",
    "task_start",
    "task_stop",
    "task_pause",
    "task_resume",
    "estop",
    "estop_clear",
    "dock",
    "blade_control",
    "zone_sync",
    "schedule_sync",
    "attachment_select",
    "attachment_detect",
    "mower_config_update",
    "schedule_set",
}


def now_ms() -> int:
    return int(time.time() * 1000)


def build_message(message_type: str, payload: dict[str, Any]) -> str:
    return json.dumps(
        {
            "type": message_type,
            "id": str(uuid.uuid4()),
            "timestamp": now_ms(),
            "payload": payload,
        },
        separators=(",", ":"),
    )


def local_ip_candidates() -> list[str]:
    ips: set[str] = set()
    try:
        for result in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            ip = result[4][0]
            if not ip.startswith("127."):
                ips.add(ip)
    except socket.gaierror:
        pass
    return sorted(ips)


@dataclass
class SimulatedTask:
    task_id: str | None = None
    task_type: str | None = None
    zone_id: str | None = None
    zone_name: str | None = None
    status: str = "idle"
    progress_pct: float = 0.0
    area_completed_sq_m: float = 0.0
    area_total_sq_m: float = 0.0
    elapsed_seconds: int = 0
    battery_used_pct: float = 0.0
    parameters: dict[str, Any] = field(default_factory=dict)
    started_at: float | None = None
    paused_at: float | None = None

    @property
    def is_active(self) -> bool:
        return self.status in {"running", "paused"}

    def start(self, payload: dict[str, Any]) -> None:
        self.task_id = str(payload.get("task_id") or payload.get("taskId") or uuid.uuid4())
        self.task_type = str(payload.get("task_type") or payload.get("taskType") or "mow")
        self.zone_id = str(payload.get("zone_id") or payload.get("zoneId") or "")
        self.zone_name = str(payload.get("zone_name") or payload.get("zoneName") or "Zone")
        self.area_total_sq_m = float(
            payload.get("total_area_sq_m") or payload.get("area_total_sq_m") or 100.0
        )
        self.parameters = dict(payload.get("parameters") or {})
        self.status = "running"
        self.progress_pct = 0.0
        self.area_completed_sq_m = 0.0
        self.elapsed_seconds = 0
        self.battery_used_pct = 0.0
        self.started_at = time.time()
        self.paused_at = None

    def pause(self) -> None:
        if self.status == "running":
            self.status = "paused"
            self.paused_at = time.time()

    def resume(self) -> None:
        if self.status == "paused":
            self.status = "running"
            self.paused_at = None

    def stop(self, status: str = "cancelled") -> None:
        if self.is_active:
            self.status = status

    def tick(self) -> None:
        if self.status != "running":
            return
        self.elapsed_seconds += 1
        self.progress_pct = min(100.0, self.progress_pct + 1.25)
        self.area_completed_sq_m = self.area_total_sq_m * (self.progress_pct / 100.0)
        self.battery_used_pct = min(100.0, self.battery_used_pct + 0.18)
        if self.progress_pct >= 100.0:
            self.status = "completed"

    def to_payload(self) -> dict[str, Any]:
        return {
            "task_id": self.task_id,
            "task_type": self.task_type,
            "zone_id": self.zone_id,
            "zone_name": self.zone_name,
            "status": self.status,
            "progress_pct": round(self.progress_pct, 1),
            "area_completed_sq_m": round(self.area_completed_sq_m, 1),
            "area_total_sq_m": round(self.area_total_sq_m, 1),
            "elapsed_seconds": self.elapsed_seconds,
            "battery_used_pct": round(self.battery_used_pct, 1),
            "can_resume": self.status == "paused",
            "parameters": self.parameters,
        }


@dataclass
class SimulatedRobotState:
    task: SimulatedTask = field(default_factory=SimulatedTask)
    estop_active: bool = False
    blade_on: bool = False
    last_drive: dict[str, Any] = field(default_factory=dict)
    boot_time: float = field(default_factory=time.time)
    battery_percent: float = 78.0
    heading_deg: float = 0.0
    selected_attachment: str = "mower"

    def telemetry_payload(self) -> dict[str, Any]:
        uptime = time.time() - self.boot_time
        if self.task.status == "running":
            self.battery_percent = max(0.0, self.battery_percent - 0.01)
        self.heading_deg = (self.heading_deg + 4.0) % 360.0
        speed = abs(float(self.last_drive.get("linear_x", 0.0))) * 0.8
        angular = float(self.last_drive.get("angular_z", 0.0))
        return {
            "battery": {
                "percent": round(self.battery_percent, 1),
                "voltage": 24.8,
                "current_amps": round(1.5 + speed * 4.0, 2),
                "temp_c": 31.0,
                "health_pct": 98,
                "cycles": 12,
            },
            "motion": {
                "speed_ms": round(speed, 3),
                "heading_deg": round(self.heading_deg, 1),
                "angular_z": round(angular, 3),
                "latitude": 0.0,
                "longitude": 0.0,
            },
            "gps": {
                "latitude": 0.0,
                "longitude": 0.0,
                "rtk_status": "simulated",
                "satellite_count": 14,
                "accuracy_cm": 2.5,
            },
            "motors": self._motor_payload(speed, angular),
            "system": {
                "temp_c": round(42.0 + math.sin(uptime / 20.0), 1),
                "state": self._system_state,
                "active_task_id": self.task.task_id,
                "signal_strength": 4,
                "attachment_type": self._attachment_type,
                "estop_active": self.estop_active,
                "blade_on": self.blade_on,
            },
        }

    def _motor_payload(self, speed: float, angular: float) -> dict[str, int]:
        base = int(speed * 120)
        turn = int(angular * 45)
        return {
            "fl_rpm": base - turn,
            "fr_rpm": base + turn,
            "rl_rpm": base - turn,
            "rr_rpm": base + turn,
        }

    @property
    def _system_state(self) -> str:
        if self.estop_active:
            return "estop"
        if self.task.status == "running":
            return "working"
        if self.task.status == "paused":
            return "paused"
        return "idle"

    @property
    def _attachment_type(self) -> str:
        if self.task.task_type == "plow":
            return "snow_plow"
        if self.task.task_type == "collect":
            return "leaf_collector"
        if self.task.task_type == "mow":
            return "mower_blade"
        return "none"


class SimulatedRobotServer:
    def __init__(self, host: str, port: int, auth_token: str | None) -> None:
        self.host = host
        self.port = port
        self.auth_token = auth_token
        self.state = SimulatedRobotState()
        self.clients: set[Any] = set()
        self._server: Any | None = None
        self._telemetry_task: asyncio.Task | None = None
        self._task_task: asyncio.Task | None = None

    async def start(self) -> None:
        self._server = await websockets.serve(
            self._handle_client,
            self.host,
            self.port,
            max_size=65536,
        )
        self._telemetry_task = asyncio.create_task(self._telemetry_loop())
        self._task_task = asyncio.create_task(self._task_loop())

    async def stop(self) -> None:
        for task in (self._telemetry_task, self._task_task):
            if task:
                task.cancel()
        for client in list(self.clients):
            await client.close(1001, "server stopping")
        if self._server:
            self._server.close()
            await self._server.wait_closed()

    async def _handle_client(self, websocket: Any, path: str | None = None) -> None:
        peer = getattr(websocket, "remote_address", "unknown")
        if not self._is_authorized(websocket):
            print(f"[reject] {peer} invalid token")
            await websocket.close(4001, "Unauthorized")
            return
        self.clients.add(websocket)
        print(f"[connect] {peer}")
        try:
            async for raw in websocket:
                await self._handle_message(websocket, raw)
        except ConnectionClosed as exc:
            print(f"[disconnect] {peer} code={exc.code} reason={exc.reason}")
        finally:
            self.clients.discard(websocket)

    def _is_authorized(self, websocket: Any) -> bool:
        if not self.auth_token:
            return True
        headers = getattr(websocket, "request_headers", {}) or {}
        return headers.get("X-Pairing-Token") == self.auth_token

    async def _handle_message(self, websocket: Any, raw: str) -> None:
        try:
            message = json.loads(raw)
        except json.JSONDecodeError:
            await websocket.send(self._ack("", "rejected", "invalid_json"))
            return

        if not isinstance(message, dict):
            await websocket.send(self._ack("", "rejected", "message_must_be_object"))
            return

        message_type = str(message.get("type", ""))
        message_id = str(message.get("id", ""))
        payload = message.get("payload") if isinstance(message.get("payload"), dict) else {}

        print(f"[{time.strftime('%H:%M:%S')}] {message_type} {payload}")

        if message_type == "ping":
            await websocket.send(build_message("pong", {"ping_id": message_id, "status": "received"}))
            print(f"[ack] pong command_id={message_id}")
            return

        if message_type not in VALID_MESSAGE_TYPES:
            await websocket.send(self._ack(message_id, "rejected", f"unknown_type:{message_type}"))
            print(f"[reject] {message_type} command_id={message_id}")
            return

        if self.state.estop_active and message_type not in {"estop", "estop_clear"}:
            await websocket.send(self._ack(message_id, "rejected", "estop_active"))
            print(f"[reject] {message_type} command_id={message_id} estop_active")
            return

        if message_type == "attachment_detect":
            await websocket.send(build_message("command_ack", {
                "command_id": message_id,
                "status": "accepted",
                "attachment": self.state.selected_attachment,
                "message": "Simulated attachment detected",
            }))
            print(f"[ack] attachment_detect command_id={message_id}")
            return

        if message_type == "attachment_select" and payload.get("attachment") not in {
            "mower", "trimmer", "irrigator", "collector", "blower", "plow", "patrol"
        }:
            await websocket.send(self._ack(message_id, "rejected", "unknown_attachment"))
            return

        self._apply_command(message_type, payload)
        await websocket.send(self._ack(message_id, "accepted", f"{message_type} accepted"))
        print(f"[ack] {message_type} command_id={message_id}")

        if message_type in {"task_start", "task_pause", "task_resume", "task_stop", "estop"}:
            await self._broadcast(build_message("task_update", self.state.task.to_payload()))
        if message_type in {"estop", "estop_clear"}:
            await self._broadcast(
                build_message(
                    "estop_status",
                    {
                        "active": self.state.estop_active,
                        "source": "app_websocket",
                        "triggered_at": now_ms() if self.state.estop_active else 0,
                    },
                )
            )

    def _apply_command(self, message_type: str, payload: dict[str, Any]) -> None:
        if message_type == "drive_command":
            self.state.last_drive = payload
            self._ros_publish("/cmd_vel", payload)
        elif message_type == "task_start":
            self.state.task.start(payload)
            self._ros_publish("/task/start", payload)
        elif message_type == "task_pause":
            self.state.task.pause()
            self._ros_publish("/task/pause", payload)
        elif message_type == "task_resume":
            self.state.task.resume()
            self._ros_publish("/task/resume", payload)
        elif message_type == "task_stop":
            self.state.task.stop("cancelled" if payload.get("reason") == "user_cancelled" else "stopped")
            self._ros_publish("/task/stop", payload)
        elif message_type == "estop":
            task_was_active = self.state.task.is_active
            self.state.task.stop("stopped")
            self.state.estop_active = True
            self.state.blade_on = False
            self.state.last_drive = {"linear_x": 0.0, "angular_z": 0.0}
            if task_was_active:
                self._ros_publish(
                    "/task/stop",
                    {"task_id": self.state.task.task_id, "reason": "emergency_stop"},
                )
            self._ros_publish("/estop/command", {"active": True})
            self._ros_publish("/cmd_vel", self.state.last_drive)
        elif message_type == "estop_clear":
            self.state.estop_active = False
            self._ros_publish("/estop/command", {"active": False})
        elif message_type == "dock":
            self._ros_publish("/dock/command", payload)
        elif message_type == "blade_control":
            self.state.blade_on = bool(payload.get("enabled", False))
            self._ros_publish("/blade/command", {"enabled": self.state.blade_on})
        elif message_type == "zone_sync":
            self._ros_publish("/zones/update", payload)
        elif message_type == "schedule_sync":
            self._ros_publish("/schedules/update", payload)
        elif message_type == "attachment_select":
            self.state.selected_attachment = payload["attachment"]
            self._ros_publish("/attachments/select", payload)
        elif message_type == "mower_config_update":
            self._ros_publish("/mower/config", payload)
        elif message_type == "schedule_set":
            self._ros_publish("/schedules/set", payload)

    def _ack(self, command_id: str, status: str, message: str) -> str:
        return build_message(
            "command_ack",
            {
                "command_id": command_id,
                "status": status,
                "message": message,
            },
        )

    def _ros_publish(self, topic: str, payload: dict[str, Any]) -> None:
        print(f"[ros2] publish {topic} {payload}")

    async def _telemetry_loop(self) -> None:
        while True:
            await asyncio.sleep(1.0)
            await self._broadcast(build_message("telemetry", self.state.telemetry_payload()))

    async def _task_loop(self) -> None:
        while True:
            await asyncio.sleep(1.0)
            if self.state.task.is_active:
                self.state.task.tick()
                await self._broadcast(build_message("task_update", self.state.task.to_payload()))

    async def _broadcast(self, message: str) -> None:
        disconnected = []
        for client in self.clients:
            try:
                await client.send(message)
            except ConnectionClosed:
                disconnected.append(client)
        for client in disconnected:
            self.clients.discard(client)


async def amain() -> None:
    parser = argparse.ArgumentParser(description="ChoreRobotics simulated robot server")
    parser.add_argument("--host", default=os.environ.get("CHOREROBOT_SIM_HOST", "0.0.0.0"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("CHOREROBOT_SIM_PORT", "8765")))
    parser.add_argument("--token", default=os.environ.get("CHOREROBOT_SIM_TOKEN"))
    args = parser.parse_args()

    server = SimulatedRobotServer(args.host, args.port, args.token)
    await server.start()

    print("ChoreRobotics simulated robot server")
    print(f"Listening on {args.host}:{args.port}")
    if args.token:
        print("Auth: X-Pairing-Token required")
    else:
        print("Auth: disabled for local testing")
    urls = [f"ws://{ip}:{args.port}/ws" for ip in local_ip_candidates()]
    if urls:
        print("Use one of these URLs in the app:")
        for url in urls:
            print(f"  {url}")
    else:
        print(f"Use ws://<your-laptop-ip>:{args.port}/ws in the app")
    print("Press Ctrl+C to stop.\n")

    try:
        await asyncio.Future()
    finally:
        await server.stop()


def main() -> None:
    try:
        asyncio.run(amain())
    except KeyboardInterrupt:
        print("\nServer stopped.")


if __name__ == "__main__":
    main()
