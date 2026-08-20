"""Local WebSocket command server for Phase 1 demos.

Run from the repo root:
    python scripts/dev_server/command_echo_server.py

The phone app connects to:
    ws://<your-laptop-lan-ip>:8765/ws

This server stands in for the robot. It logs commands from the Flutter app and
responds with command_ack messages so the app can show "received ✓".
"""

from __future__ import annotations

import argparse
import asyncio
import json
import socket
import time
import uuid
from typing import Any

try:
    import websockets
except ImportError as exc:  # pragma: no cover - startup guidance
    raise SystemExit(
        "Missing dependency: websockets\n"
        "Install with: python -m pip install -r scripts/robot_server/requirements.txt"
    ) from exc


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
    hostname = socket.gethostname()
    try:
      for result in socket.getaddrinfo(hostname, None, socket.AF_INET):
          ip = result[4][0]
          if not ip.startswith("127."):
              ips.add(ip)
    except socket.gaierror:
        pass
    return sorted(ips)


async def handle_client(websocket: Any) -> None:
    peer = getattr(websocket, "remote_address", "unknown")
    print(f"[connect] {peer}")
    try:
        async for raw in websocket:
            try:
                message = json.loads(raw)
            except json.JSONDecodeError:
                await websocket.send(
                    build_message(
                        "command_ack",
                        {
                            "command_id": "",
                            "status": "rejected",
                            "message": "invalid_json",
                        },
                    )
                )
                continue

            message_type = str(message.get("type", "unknown"))
            message_id = str(message.get("id", ""))
            payload = message.get("payload") or {}
            print(f"[{time.strftime('%H:%M:%S')}] {message_type} {payload}")

            if message_type == "ping":
                reply = build_message("pong", {"command_id": message_id, "status": "received"})
                await websocket.send(reply)
                print(f"[ack] pong command_id={message_id}")
                continue

            reply = build_message(
                "command_ack",
                {
                    "command_id": message_id,
                    "status": "received",
                    "message": f"{message_type} received",
                    "echo": payload,
                },
            )
            await websocket.send(reply)
            print(f"[ack] {message_type} command_id={message_id}")
    finally:
        print(f"[disconnect] {peer}")


async def main() -> None:
    parser = argparse.ArgumentParser(description="ChoreRobotics Phase 1 command echo server")
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", default=8765, type=int)
    args = parser.parse_args()

    urls = [f"ws://{ip}:{args.port}/ws" for ip in local_ip_candidates()]
    print("ChoreRobotics command echo server")
    print(f"Listening on {args.host}:{args.port}")
    if urls:
        print("Use one of these URLs in the app:")
        for url in urls:
            print(f"  {url}")
    else:
        print(f"Use ws://<your-laptop-ip>:{args.port}/ws in the app")
    print("Press Ctrl+C to stop.\n")

    async with websockets.serve(handle_client, args.host, args.port):
        await asyncio.Future()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nServer stopped.")
