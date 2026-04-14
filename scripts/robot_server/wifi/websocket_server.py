"""
WebSocket Server.

Runs an asyncio-based WebSocket server on port 8765 that accepts
connections from the Flutter app on the local network. Provides
bidirectional JSON messaging for commands and telemetry.

Features:
    - Token-based authentication on handshake
    - mDNS advertisement for automatic discovery
    - Telemetry streaming at 10Hz
    - Task progress updates at 1Hz
    - Command processing with acknowledgements
    - Heartbeat/keepalive mechanism (ping every 5s)
    - Maximum 3 simultaneous connections

Dependencies:
    - websockets (asyncio WebSocket library)
    - zeroconf (mDNS advertisement)
"""

import asyncio
import logging
import time
from typing import Optional, Callable, Dict, Any, Set, List

from ..models.robot_state import RobotState
from ..models.telemetry import TelemetrySnapshot
from ..models.command import (
    DriveCommand,
    TaskStartCommand,
    TaskStopCommand,
    BladeCommand,
    EStopCommand,
    DockCommand,
    CommandSource,
)
from .protocol import MessageProtocol
from .auth import WebSocketAuth
from ..config import (
    WEBSOCKET_HOST,
    WEBSOCKET_PORT,
    WEBSOCKET_PATH,
    WEBSOCKET_HEARTBEAT_INTERVAL_S,
    WEBSOCKET_HEARTBEAT_TIMEOUT_S,
    WEBSOCKET_MAX_CONNECTIONS,
    WEBSOCKET_MAX_MESSAGE_SIZE_BYTES,
    MDNS_SERVICE_TYPE,
    MDNS_SERVICE_PORT,
    ROBOT_SERIAL,
    TELEMETRY_WIFI_HZ,
    TELEMETRY_TASK_PROGRESS_HZ,
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
)

logger = logging.getLogger(__name__)


class WebSocketServer:
    """Asyncio WebSocket server for local app-to-robot communication.

    Manages client connections, message routing, and periodic telemetry
    broadcasting. Integrates with mDNS for automatic discovery.

    Usage:
        server = WebSocketServer(robot_state, telemetry, auth)
        server.on_drive_command = handle_drive
        server.on_estop = handle_estop
        await server.start()
        ...
        await server.stop()
    """

    def __init__(
        self,
        robot_state: RobotState,
        telemetry: TelemetrySnapshot,
        auth: WebSocketAuth,
    ) -> None:
        """Initialize the WebSocket server.

        Args:
            robot_state: Shared robot state for command validation.
            telemetry: Shared telemetry snapshot for streaming.
            auth: WebSocket authentication handler.
        """
        self._robot_state = robot_state
        self._telemetry = telemetry
        self._auth = auth
        self._is_running: bool = False
        self._server: Optional[Any] = None  # websockets.WebSocketServer

        # Connected clients (websocket -> client_id)
        self._clients: Dict[Any, str] = {}

        # Periodic tasks
        self._telemetry_task: Optional[asyncio.Task] = None
        self._task_progress_task: Optional[asyncio.Task] = None

        # Command callbacks (set by the main server)
        self.on_drive_command: Optional[Callable[[DriveCommand], None]] = None
        self.on_task_start: Optional[Callable[[TaskStartCommand], None]] = None
        self.on_task_stop: Optional[Callable[[TaskStopCommand], None]] = None
        self.on_task_pause: Optional[Callable[[], None]] = None
        self.on_task_resume: Optional[Callable[[], None]] = None
        self.on_estop: Optional[Callable[[EStopCommand], None]] = None
        self.on_blade_control: Optional[Callable[[BladeCommand], None]] = None
        self.on_dock: Optional[Callable[[DockCommand], None]] = None
        self.on_zone_sync: Optional[Callable[[Dict[str, Any]], None]] = None
        self.on_schedule_sync: Optional[Callable[[Dict[str, Any]], None]] = None

    async def start(self) -> None:
        """Start the WebSocket server and mDNS advertisement.

        Binds to WEBSOCKET_HOST:WEBSOCKET_PORT and begins accepting
        connections. Registers the mDNS service for automatic discovery.
        """
        # TODO: implement
        # 1. Start websockets.serve() on configured host:port
        # 2. Register mDNS service via zeroconf
        logger.info(f"Starting WebSocket server on {WEBSOCKET_HOST}:{WEBSOCKET_PORT}")
        self._is_running = True
        self._start_broadcast_tasks()

    async def stop(self) -> None:
        """Stop the WebSocket server and mDNS advertisement.

        Closes all client connections, cancels broadcast tasks,
        unregisters mDNS, and stops the server.
        """
        # TODO: implement
        logger.info("Stopping WebSocket server")
        self._is_running = False
        self._stop_broadcast_tasks()
        await self._close_all_clients()

    async def _handle_connection(self, websocket: Any, path: str) -> None:
        """Handle a new WebSocket connection.

        Authenticates the client, registers it, processes messages,
        and handles disconnection.

        Args:
            websocket: The websockets.WebSocketServerProtocol instance.
            path: The requested URL path (must match WEBSOCKET_PATH).
        """
        # TODO: implement
        # 1. Validate path == WEBSOCKET_PATH
        # 2. Extract headers and validate token
        # 3. Check max connections
        # 4. Register client
        # 5. Enter message processing loop
        # 6. On disconnect, unregister client

        client_id = "unknown"
        try:
            # Authenticate
            headers = dict(websocket.request_headers) if hasattr(websocket, 'request_headers') else {}
            is_valid, client_id_result = self._auth.validate_handshake(headers)

            if not is_valid:
                logger.warning("WebSocket connection rejected: invalid token")
                await websocket.close(4001, "Unauthorized")
                return

            client_id = client_id_result or "unknown"

            # Check max connections
            if len(self._clients) >= WEBSOCKET_MAX_CONNECTIONS:
                logger.warning("WebSocket connection rejected: max connections reached")
                await websocket.close(4002, "Too many connections")
                return

            # Register
            self._clients[websocket] = client_id
            self._robot_state.connection.websocket_clients = len(self._clients)
            self._auth.register_client(client_id, {
                "connected_at": time.time(),
            })

            logger.info(f"WebSocket client connected: {client_id}")

            # Message loop
            async for raw_message in websocket:
                await self._handle_message(websocket, client_id, raw_message)

        except Exception as e:
            logger.error(f"WebSocket error for {client_id}: {e}")
        finally:
            # Cleanup
            self._clients.pop(websocket, None)
            self._robot_state.connection.websocket_clients = len(self._clients)
            if client_id:
                self._auth.unregister_client(client_id)
            logger.info(f"WebSocket client disconnected: {client_id}")

    async def _handle_message(
        self,
        websocket: Any,
        client_id: str,
        raw: str,
    ) -> None:
        """Process a single incoming WebSocket message.

        Parses the JSON envelope, validates the message type, and
        routes to the appropriate command handler.

        Args:
            websocket: The client's WebSocket connection.
            client_id: Authenticated client identifier.
            raw: Raw JSON string from the WebSocket frame.
        """
        msg = MessageProtocol.parse(raw)
        if msg is None:
            return

        msg_type = msg["type"]
        msg_id = msg["id"]
        payload = msg["payload"]

        # Update activity timestamp
        self._robot_state.connection.last_websocket_activity_ms = int(time.time() * 1000)

        # Route by message type
        if msg_type == MSG_TYPE_PING:
            pong = MessageProtocol.build_pong(msg_id)
            await websocket.send(pong)

        elif msg_type == MSG_TYPE_DRIVE_COMMAND:
            cmd = DriveCommand.from_websocket_dict(payload)
            if self.on_drive_command:
                self.on_drive_command(cmd)

        elif msg_type == MSG_TYPE_TASK_START:
            cmd = TaskStartCommand.from_websocket_dict(msg_id, payload)
            ack = MessageProtocol.build_command_ack(msg_id, "accepted")
            await websocket.send(ack)
            if self.on_task_start:
                self.on_task_start(cmd)

        elif msg_type == MSG_TYPE_TASK_STOP:
            cmd = TaskStopCommand(
                command_id=msg_id,
                reason=payload.get("reason", "user_requested"),
                source=CommandSource.WEBSOCKET,
            )
            ack = MessageProtocol.build_command_ack(msg_id, "accepted")
            await websocket.send(ack)
            if self.on_task_stop:
                self.on_task_stop(cmd)

        elif msg_type == MSG_TYPE_TASK_PAUSE:
            ack = MessageProtocol.build_command_ack(msg_id, "accepted")
            await websocket.send(ack)
            if self.on_task_pause:
                self.on_task_pause()

        elif msg_type == MSG_TYPE_TASK_RESUME:
            ack = MessageProtocol.build_command_ack(msg_id, "accepted")
            await websocket.send(ack)
            if self.on_task_resume:
                self.on_task_resume()

        elif msg_type == MSG_TYPE_ESTOP:
            cmd = EStopCommand.from_websocket_dict(payload)
            if self.on_estop:
                self.on_estop(cmd)
            # Ack E-Stop immediately
            ack = MessageProtocol.build_command_ack(msg_id, "accepted")
            await websocket.send(ack)

        elif msg_type == MSG_TYPE_ESTOP_CLEAR:
            cmd = EStopCommand(
                activate=False,
                confirmation_code=payload.get("confirmation_code"),
                source=CommandSource.WEBSOCKET,
            )
            if self.on_estop:
                self.on_estop(cmd)
            ack = MessageProtocol.build_command_ack(msg_id, "accepted")
            await websocket.send(ack)

        elif msg_type == MSG_TYPE_DOCK:
            cmd = DockCommand(command_id=msg_id, source=CommandSource.WEBSOCKET)
            ack = MessageProtocol.build_command_ack(msg_id, "accepted")
            await websocket.send(ack)
            if self.on_dock:
                self.on_dock(cmd)

        elif msg_type == MSG_TYPE_BLADE_CONTROL:
            cmd = BladeCommand(
                enabled=payload.get("enabled", False),
                source=CommandSource.WEBSOCKET,
            )
            if self.on_blade_control:
                self.on_blade_control(cmd)

        elif msg_type == MSG_TYPE_ZONE_SYNC:
            if self.on_zone_sync:
                self.on_zone_sync(payload)
            ack = MessageProtocol.build_command_ack(msg_id, "accepted")
            await websocket.send(ack)

        elif msg_type == MSG_TYPE_SCHEDULE_SYNC:
            if self.on_schedule_sync:
                self.on_schedule_sync(payload)
            ack = MessageProtocol.build_command_ack(msg_id, "accepted")
            await websocket.send(ack)

    # =========================================================================
    # Broadcasting (robot -> all connected clients)
    # =========================================================================

    async def broadcast(self, message: str) -> None:
        """Send a message to all connected WebSocket clients.

        Silently drops messages for clients that have disconnected.

        Args:
            message: JSON string to broadcast.
        """
        disconnected = []
        for ws, client_id in self._clients.items():
            try:
                await ws.send(message)
            except Exception:
                disconnected.append(ws)

        for ws in disconnected:
            self._clients.pop(ws, None)

    async def broadcast_telemetry(self) -> None:
        """Broadcast the current telemetry snapshot to all clients."""
        if not self._clients:
            return
        msg = MessageProtocol.build_telemetry(self._telemetry.to_dict())
        await self.broadcast(msg)

    async def broadcast_task_update(self) -> None:
        """Broadcast the current task progress to all clients."""
        if not self._clients or not self._robot_state.task.is_active():
            return
        msg = MessageProtocol.build_task_update(
            self._robot_state.task.to_websocket_dict()
        )
        await self.broadcast(msg)

    async def broadcast_alert(self, alert_dict: Dict[str, Any]) -> None:
        """Broadcast a diagnostic alert to all clients.

        Args:
            alert_dict: Alert data from AlertEntry.to_websocket_dict().
        """
        msg = MessageProtocol.build_alert(alert_dict)
        await self.broadcast(msg)

    async def broadcast_estop_status(
        self, active: bool, source: str, triggered_at: int
    ) -> None:
        """Broadcast E-Stop status change to all clients.

        Args:
            active: Whether E-Stop is active.
            source: Source of the E-Stop event.
            triggered_at: Unix ms of the event.
        """
        msg = MessageProtocol.build_estop_status(active, source, triggered_at)
        await self.broadcast(msg)

    # =========================================================================
    # Periodic broadcast tasks
    # =========================================================================

    def _start_broadcast_tasks(self) -> None:
        """Start periodic telemetry and task progress broadcast tasks."""
        self._telemetry_task = asyncio.create_task(
            self._broadcast_loop(
                "telemetry",
                1.0 / TELEMETRY_WIFI_HZ,
                self.broadcast_telemetry,
            )
        )
        self._task_progress_task = asyncio.create_task(
            self._broadcast_loop(
                "task_progress",
                1.0 / TELEMETRY_TASK_PROGRESS_HZ,
                self.broadcast_task_update,
            )
        )

    def _stop_broadcast_tasks(self) -> None:
        """Cancel periodic broadcast tasks."""
        for task in [self._telemetry_task, self._task_progress_task]:
            if task and not task.done():
                task.cancel()

    async def _broadcast_loop(
        self,
        name: str,
        interval_s: float,
        broadcast_fn: Callable,
    ) -> None:
        """Generic periodic broadcast loop.

        Args:
            name: Loop name for logging.
            interval_s: Seconds between broadcasts.
            broadcast_fn: Async callable to invoke each cycle.
        """
        while self._is_running:
            try:
                await broadcast_fn()
                await asyncio.sleep(interval_s)
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Error in {name} broadcast loop: {e}")
                await asyncio.sleep(interval_s)

    async def _close_all_clients(self) -> None:
        """Close all active WebSocket connections."""
        for ws in list(self._clients.keys()):
            try:
                await ws.close(1000, "Server shutting down")
            except Exception:
                pass
        self._clients.clear()

    @property
    def client_count(self) -> int:
        """Number of currently connected WebSocket clients."""
        return len(self._clients)
