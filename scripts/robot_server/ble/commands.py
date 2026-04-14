"""
BLE Command Handler.

Processes incoming commands from BLE GATT write operations and routes
them to the appropriate ROS2 publisher or internal handler.

This module acts as the BLE-specific command ingestion layer. It validates
commands, checks safety constraints, and forwards them to the shared
command router used by all communication channels.

Safety rules enforced here:
    - E-Stop is always accepted regardless of robot state
    - Drive commands are rejected if robot is in E-Stop
    - Blade commands are only accepted from local connections (BLE/WiFi)
    - Task commands are rejected if robot is in E-Stop
"""

import asyncio
import json
import logging
from typing import Optional, Callable, Dict, Any

from ..models.robot_state import RobotState
from ..models.command import (
    DriveCommand,
    TaskStartCommand,
    TaskStopCommand,
    BladeCommand,
    EStopCommand,
    DockCommand,
    CommandSource,
)

logger = logging.getLogger(__name__)


class BleCommandHandler:
    """Processes and routes commands received via BLE GATT writes.

    The BLE command handler is instantiated by the main server and
    connected to the GattServer's write callbacks. It validates
    incoming commands and forwards them to the central command router.

    Usage:
        handler = BleCommandHandler(robot_state)
        handler.on_drive = command_router.handle_drive
        handler.on_task_start = command_router.handle_task_start
        handler.on_estop = command_router.handle_estop

        # Connect to GATT server:
        gatt_server.on_drive_command = handler.handle_drive_command
        gatt_server.on_estop = handler.handle_estop
    """

    def __init__(self, robot_state: RobotState) -> None:
        """Initialize the BLE command handler.

        Args:
            robot_state: Shared robot state for safety checks.
        """
        self._robot_state = robot_state

        # Output callbacks (set by the main server)
        self.on_drive: Optional[Callable[[DriveCommand], None]] = None
        """Forward validated drive commands to the command router."""

        self.on_task_start: Optional[Callable[[TaskStartCommand], None]] = None
        """Forward validated task start commands."""

        self.on_task_stop: Optional[Callable[[TaskStopCommand], None]] = None
        """Forward validated task stop commands."""

        self.on_task_pause: Optional[Callable[[], None]] = None
        """Forward task pause commands."""

        self.on_task_resume: Optional[Callable[[], None]] = None
        """Forward task resume commands."""

        self.on_estop: Optional[Callable[[EStopCommand], None]] = None
        """Forward E-Stop commands (always accepted)."""

        self.on_blade: Optional[Callable[[BladeCommand], None]] = None
        """Forward blade control commands."""

        self.on_dock: Optional[Callable[[DockCommand], None]] = None
        """Forward return-to-dock commands."""

    def handle_drive_command(self, cmd: DriveCommand) -> None:
        """Handle a drive command from BLE write.

        Validates that the robot is not in E-Stop before forwarding.
        Drive commands arrive at 30Hz, so this must be fast (no I/O).

        Args:
            cmd: Parsed DriveCommand from 4-byte BLE write.
        """
        if not self._robot_state.can_accept_command("drive_command"):
            return  # Silently drop -- E-Stop active

        if self.on_drive:
            self.on_drive(cmd)

    def handle_task_command(self, command_data: Dict[str, Any]) -> None:
        """Handle a task command from BLE JSON write.

        Parses the JSON command and routes to the appropriate handler
        based on the 'command' field.

        Args:
            command_data: Parsed JSON dict from BLE CHOR0302 write.
                Expected format: {"command": "start", "task_type": "mow", ...}
        """
        command_type = command_data.get("command", "")

        if not self._robot_state.can_accept_command(f"task_{command_type}"):
            logger.warning(f"Task command '{command_type}' rejected: robot in E-Stop")
            return

        if command_type == "start":
            cmd = TaskStartCommand(
                task_type=command_data.get("task_type", "mow"),
                zone_id=command_data.get("zone_id", ""),
                parameters=command_data.get("parameters"),
                source=CommandSource.BLE,
            )
            if self.on_task_start:
                self.on_task_start(cmd)

        elif command_type == "stop":
            cmd = TaskStopCommand(
                reason=command_data.get("reason", "user_requested"),
                source=CommandSource.BLE,
            )
            if self.on_task_stop:
                self.on_task_stop(cmd)

        elif command_type == "pause":
            if self.on_task_pause:
                self.on_task_pause()

        elif command_type == "resume":
            if self.on_task_resume:
                self.on_task_resume()

        elif command_type == "dock":
            cmd = DockCommand(source=CommandSource.BLE)
            if self.on_dock:
                self.on_dock(cmd)

        else:
            logger.warning(f"Unknown BLE task command: {command_type}")

    def handle_estop(self, cmd: EStopCommand) -> None:
        """Handle E-Stop from BLE write.

        E-Stop commands are ALWAYS accepted regardless of robot state.
        They bypass all safety checks and are forwarded immediately.

        Args:
            cmd: Parsed EStopCommand from 1-byte BLE write.
        """
        logger.warning(f"BLE E-Stop: activate={cmd.activate}")
        if self.on_estop:
            self.on_estop(cmd)

    def handle_blade_command(self, cmd: BladeCommand) -> None:
        """Handle blade toggle from BLE write.

        Validates:
        - Robot is not in E-Stop
        - Command source is local (BLE is always local)

        Args:
            cmd: Parsed BladeCommand from 1-byte BLE write.
        """
        if not self._robot_state.can_accept_command("blade_control"):
            logger.warning("Blade command rejected: robot in E-Stop")
            return

        if not cmd.is_safe_source():
            logger.warning("Blade command rejected: unsafe source")
            return

        if self.on_blade:
            self.on_blade(cmd)
