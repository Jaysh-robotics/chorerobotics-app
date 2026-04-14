"""
Firebase Command Listener.

Listens for pending commands in the Firestore commands subcollection
using a real-time snapshot listener. When a new command arrives with
status "pending", the listener acknowledges it, routes it to the
appropriate handler, and updates the command status through its lifecycle.

Command Lifecycle:
    pending -> acknowledged -> executing -> completed/failed

If the snapshot listener fails (network issue), falls back to polling
every 5 seconds.
"""

import asyncio
import logging
import time
from typing import Optional, Callable, Dict, Any, List

from ..models.command import (
    TaskStartCommand,
    TaskStopCommand,
    EStopCommand,
    DockCommand,
    CommandSource,
)
from ..models.robot_state import RobotState
from .client import FirebaseClient
from ..config import (
    FIREBASE_COMMAND_POLL_INTERVAL_S,
    ROBOT_SERIAL,
)

logger = logging.getLogger(__name__)


class CommandListener:
    """Listens for and processes cloud commands from Firestore.

    The command listener monitors the commands subcollection for the
    robot and dispatches incoming commands to the appropriate handler.
    It manages the command lifecycle state machine.

    Usage:
        listener = CommandListener(firebase_client, robot_state)
        listener.on_task_start = handle_task_start
        listener.on_estop = handle_estop
        await listener.start()
        ...
        await listener.stop()
    """

    def __init__(
        self,
        firebase_client: FirebaseClient,
        robot_state: RobotState,
    ) -> None:
        """Initialize the command listener.

        Args:
            firebase_client: Firebase client for reading/writing commands.
            robot_state: Robot state for command validation.
        """
        self._client = firebase_client
        self._robot_state = robot_state
        self._is_running: bool = False
        self._listener_task: Optional[asyncio.Task] = None
        self._snapshot_listener: Optional[Any] = None  # Firestore listener handle
        self._processed_command_ids: set = set()

        # Command callbacks (set by the main server)
        self.on_task_start: Optional[Callable[[TaskStartCommand], None]] = None
        self.on_task_stop: Optional[Callable[[TaskStopCommand], None]] = None
        self.on_task_pause: Optional[Callable[[], None]] = None
        self.on_task_resume: Optional[Callable[[], None]] = None
        self.on_estop: Optional[Callable[[EStopCommand], None]] = None
        self.on_dock: Optional[Callable[[DockCommand], None]] = None
        self.on_firmware_update: Optional[Callable[[Dict[str, Any]], None]] = None
        self.on_zone_sync_requested: Optional[Callable[[], None]] = None
        self.on_schedule_sync_requested: Optional[Callable[[], None]] = None

    async def start(self) -> None:
        """Start listening for commands.

        Attempts to set up a Firestore snapshot listener. Falls back to
        polling if the listener cannot be established.
        """
        logger.info("Starting command listener")
        self._is_running = True

        try:
            await self._start_snapshot_listener()
        except Exception as e:
            logger.warning(f"Snapshot listener failed, falling back to polling: {e}")
            self._listener_task = asyncio.create_task(self._polling_loop())

    async def stop(self) -> None:
        """Stop listening for commands.

        Cancels the snapshot listener or polling task.
        """
        logger.info("Stopping command listener")
        self._is_running = False

        if self._snapshot_listener:
            # TODO: unsubscribe from Firestore listener
            self._snapshot_listener = None

        if self._listener_task and not self._listener_task.done():
            self._listener_task.cancel()
            try:
                await self._listener_task
            except asyncio.CancelledError:
                pass

    async def _start_snapshot_listener(self) -> None:
        """Set up a Firestore snapshot listener on the commands subcollection.

        Listens for documents where status == "pending" in real-time.
        """
        # TODO: implement
        # commands_ref = firestore_db.collection('robots') \
        #     .document(ROBOT_SERIAL) \
        #     .collection('commands') \
        #     .where('status', '==', 'pending')
        #
        # self._snapshot_listener = commands_ref.on_snapshot(
        #     self._on_snapshot_callback
        # )
        pass

    def _on_snapshot_callback(
        self, docs: list, changes: list, read_time: Any
    ) -> None:
        """Callback invoked by Firestore snapshot listener.

        Called whenever new pending commands appear or existing ones change.

        Args:
            docs: All matching documents.
            changes: Document changes since last callback.
            read_time: Firestore read timestamp.
        """
        # TODO: implement
        # for change in changes:
        #     if change.type.name == 'ADDED':
        #         doc = change.document
        #         asyncio.create_task(
        #             self._process_command(doc.id, doc.to_dict())
        #         )
        pass

    async def _polling_loop(self) -> None:
        """Fallback: poll for pending commands every 5 seconds.

        Used when the snapshot listener cannot be established
        (network instability, etc.)
        """
        while self._is_running:
            try:
                await self._poll_pending_commands()
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Command polling error: {e}")

            await asyncio.sleep(FIREBASE_COMMAND_POLL_INTERVAL_S)

    async def _poll_pending_commands(self) -> None:
        """Query Firestore for pending commands and process them.

        Queries: robots/{serial}/commands where status == 'pending',
        ordered by createdAt ascending (FIFO).
        """
        # TODO: implement
        # commands_ref = firestore_db.collection('robots') \
        #     .document(ROBOT_SERIAL) \
        #     .collection('commands') \
        #     .where('status', '==', 'pending') \
        #     .order_by('createdAt') \
        #     .limit(10)
        # docs = commands_ref.stream()
        # for doc in docs:
        #     if doc.id not in self._processed_command_ids:
        #         await self._process_command(doc.id, doc.to_dict())
        pass

    async def _process_command(
        self, command_id: str, data: Dict[str, Any]
    ) -> None:
        """Process a single pending command.

        Steps:
        1. Check if already processed (deduplication)
        2. Check if expired
        3. Acknowledge the command
        4. Route to appropriate handler
        5. Update status to completed/failed

        Args:
            command_id: Firestore document ID.
            data: Command document data.
        """
        # Deduplication
        if command_id in self._processed_command_ids:
            return
        self._processed_command_ids.add(command_id)

        # Check expiry
        expires_at = data.get("expiresAt")
        if expires_at and hasattr(expires_at, 'timestamp'):
            if time.time() > expires_at.timestamp():
                logger.warning(f"Command {command_id} expired, skipping")
                return

        command_type = data.get("type", "")
        logger.info(f"Processing cloud command: {command_type} ({command_id})")

        # Acknowledge
        await self._client.acknowledge_command(command_id, "acknowledged")

        # Route by type
        try:
            await self._client.acknowledge_command(command_id, "executing")
            await self._dispatch_command(command_id, command_type, data)
            await self._client.acknowledge_command(command_id, "completed")
        except Exception as e:
            logger.error(f"Command {command_id} failed: {e}")
            await self._client.acknowledge_command(
                command_id,
                "failed",
                error={"code": "EXECUTION_ERROR", "message": str(e)},
            )

    async def _dispatch_command(
        self, command_id: str, command_type: str, data: Dict[str, Any]
    ) -> None:
        """Route a command to the appropriate handler.

        Args:
            command_id: Command document ID.
            command_type: Command type string.
            data: Full command document data.
        """
        if command_type == "start_task":
            cmd = TaskStartCommand.from_firebase_dict(command_id, data)
            if self.on_task_start:
                self.on_task_start(cmd)

        elif command_type == "stop_task":
            payload = data.get("payload", {})
            cmd = TaskStopCommand(
                command_id=command_id,
                reason=payload.get("reason", "user_requested"),
                source=CommandSource.FIREBASE,
            )
            if self.on_task_stop:
                self.on_task_stop(cmd)

        elif command_type == "pause_task":
            if self.on_task_pause:
                self.on_task_pause()

        elif command_type == "resume_task":
            if self.on_task_resume:
                self.on_task_resume()

        elif command_type == "dock":
            cmd = DockCommand(command_id=command_id, source=CommandSource.FIREBASE)
            if self.on_dock:
                self.on_dock(cmd)

        elif command_type == "estop":
            cmd = EStopCommand(activate=True, source=CommandSource.FIREBASE)
            if self.on_estop:
                self.on_estop(cmd)

        elif command_type == "clear_estop":
            cmd = EStopCommand(
                activate=False,
                confirmation_code=data.get("payload", {}).get("confirmation_code"),
                source=CommandSource.FIREBASE,
            )
            if self.on_estop:
                self.on_estop(cmd)

        elif command_type == "update_firmware":
            if self.on_firmware_update:
                self.on_firmware_update(data.get("payload", {}))

        elif command_type == "sync_zones":
            if self.on_zone_sync_requested:
                self.on_zone_sync_requested()

        elif command_type == "sync_schedules":
            if self.on_schedule_sync_requested:
                self.on_schedule_sync_requested()

        else:
            logger.warning(f"Unknown cloud command type: {command_type}")
