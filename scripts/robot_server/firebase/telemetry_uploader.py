"""
Periodic Telemetry Uploader.

Manages the scheduled upload of telemetry data to Firebase at
different intervals for different destinations:

    - Realtime Database: every 5 seconds (live telemetry)
    - Firestore snapshots: every 60 seconds when active, 300s when idle
    - Heartbeat: every 30 seconds

Runs as async tasks in the main event loop.
"""

import asyncio
import logging
import time
from typing import Optional

from ..models.telemetry import TelemetrySnapshot
from ..models.robot_state import RobotState
from .client import FirebaseClient
from ..config import (
    FIREBASE_TELEMETRY_UPLOAD_INTERVAL_S,
    FIREBASE_SNAPSHOT_INTERVAL_S,
    FIREBASE_SNAPSHOT_IDLE_INTERVAL_S,
    FIREBASE_HEARTBEAT_INTERVAL_S,
    ROBOT_STATE_WORKING,
)

logger = logging.getLogger(__name__)


class TelemetryUploader:
    """Manages periodic telemetry uploads to Firebase.

    Creates and manages three async tasks:
    1. RTDB telemetry write (every 5s)
    2. Firestore telemetry snapshot (every 60s active, 300s idle)
    3. RTDB heartbeat (every 30s)

    Usage:
        uploader = TelemetryUploader(firebase_client, telemetry, robot_state)
        await uploader.start()
        ...
        await uploader.stop()
    """

    def __init__(
        self,
        firebase_client: FirebaseClient,
        telemetry: TelemetrySnapshot,
        robot_state: RobotState,
    ) -> None:
        """Initialize the telemetry uploader.

        Args:
            firebase_client: Firebase client for data writes.
            telemetry: Shared telemetry snapshot to upload.
            robot_state: Robot state for determining upload intervals.
        """
        self._client = firebase_client
        self._telemetry = telemetry
        self._robot_state = robot_state
        self._is_running: bool = False

        # Task handles
        self._rtdb_task: Optional[asyncio.Task] = None
        self._snapshot_task: Optional[asyncio.Task] = None
        self._heartbeat_task: Optional[asyncio.Task] = None

        # Counters for monitoring
        self._rtdb_write_count: int = 0
        self._snapshot_write_count: int = 0
        self._heartbeat_count: int = 0
        self._error_count: int = 0

    async def start(self) -> None:
        """Start all periodic upload tasks.

        Creates three async tasks that run until stop() is called.
        Each task handles its own error recovery (log and continue).
        """
        logger.info("Starting telemetry uploader")
        self._is_running = True

        self._rtdb_task = asyncio.create_task(self._rtdb_upload_loop())
        self._snapshot_task = asyncio.create_task(self._snapshot_upload_loop())
        self._heartbeat_task = asyncio.create_task(self._heartbeat_loop())

    async def stop(self) -> None:
        """Stop all periodic upload tasks.

        Cancels running tasks and waits for them to complete.
        """
        logger.info(
            f"Stopping telemetry uploader. "
            f"Stats: rtdb={self._rtdb_write_count}, "
            f"snapshots={self._snapshot_write_count}, "
            f"heartbeats={self._heartbeat_count}, "
            f"errors={self._error_count}"
        )
        self._is_running = False

        for task in [self._rtdb_task, self._snapshot_task, self._heartbeat_task]:
            if task and not task.done():
                task.cancel()
                try:
                    await task
                except asyncio.CancelledError:
                    pass

    async def _rtdb_upload_loop(self) -> None:
        """Upload telemetry to Realtime Database every 5 seconds.

        Writes the full telemetry snapshot as a flat dict.
        This is the data the app reads for live dashboard updates
        when connected via cloud (no local BLE/WiFi).
        """
        while self._is_running:
            try:
                await self._client.write_telemetry(self._telemetry)
                self._rtdb_write_count += 1
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"RTDB telemetry upload failed: {e}")
                self._error_count += 1

            await asyncio.sleep(FIREBASE_TELEMETRY_UPLOAD_INTERVAL_S)

    async def _snapshot_upload_loop(self) -> None:
        """Upload telemetry snapshots to Firestore periodically.

        Interval depends on robot state:
        - Active (working): every 60 seconds
        - Idle/docked: every 300 seconds (5 minutes)

        Snapshots are used for historical analysis (battery trends,
        coverage analytics, etc.)
        """
        while self._is_running:
            try:
                await self._client.write_telemetry_snapshot(self._telemetry)
                self._snapshot_write_count += 1
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Firestore snapshot upload failed: {e}")
                self._error_count += 1

            # Adjust interval based on robot state
            if self._robot_state.operational_state.value == ROBOT_STATE_WORKING:
                interval = FIREBASE_SNAPSHOT_INTERVAL_S
            else:
                interval = FIREBASE_SNAPSHOT_IDLE_INTERVAL_S

            await asyncio.sleep(interval)

    async def _heartbeat_loop(self) -> None:
        """Write heartbeat to Realtime Database every 30 seconds.

        The heartbeat is used by Cloud Functions to detect offline robots
        and by the app to show online/offline status.
        """
        while self._is_running:
            try:
                await self._client.write_heartbeat()
                self._heartbeat_count += 1

                # Also update Firestore robot status periodically
                await self._client.update_robot_status(
                    status=self._robot_state.operational_state.value,
                    attachment_type=self._robot_state.attachment_type,
                )
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Heartbeat write failed: {e}")
                self._error_count += 1

            await asyncio.sleep(FIREBASE_HEARTBEAT_INTERVAL_S)

    async def force_snapshot(self) -> None:
        """Force an immediate telemetry snapshot write.

        Called on significant state changes (task start, task complete,
        E-Stop, error) to ensure the event is captured.
        """
        try:
            await self._client.write_telemetry_snapshot(self._telemetry)
            self._snapshot_write_count += 1
        except Exception as e:
            logger.error(f"Forced snapshot failed: {e}")
            self._error_count += 1
