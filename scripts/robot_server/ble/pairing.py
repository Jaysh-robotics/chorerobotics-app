"""
BLE Pairing State Machine.

Manages the complete pairing lifecycle from initial discovery through
code verification and token generation. Coordinates LED feedback
through the LED controller.

Pairing Flow:
    DISCOVERABLE -> FOUND -> PAIRING -> AWAITING_CODE -> VERIFYING
    -> SUCCESS -> WIFI_SETUP -> COMPLETE
    or
    -> FAILED -> (3 second delay) -> DISCOVERABLE

The pairing code is a 6-digit numeric code generated using
cryptographic randomness. The pairing token is a 32-character
hex string used for subsequent WebSocket authentication.
"""

import asyncio
import logging
import secrets
from typing import Optional, Callable

from ..models.robot_state import RobotState, PairingPhase
from ..config import (
    BLE_PAIRING_CODE_LENGTH,
    BLE_PAIRING_TOKEN_LENGTH,
    BLE_PAIRING_TIMEOUT_S,
    PAIRING_STATE_DISCOVERABLE,
    PAIRING_STATE_FOUND,
    PAIRING_STATE_PAIRING,
    PAIRING_STATE_AWAITING_CODE,
    PAIRING_STATE_VERIFYING,
    PAIRING_STATE_SUCCESS,
    PAIRING_STATE_WIFI_SETUP,
    PAIRING_STATE_COMPLETE,
    PAIRING_STATE_FAILED,
    PAIRING_RESULT_PENDING,
    PAIRING_RESULT_SUCCESS,
    PAIRING_RESULT_FAILED,
)

logger = logging.getLogger(__name__)


class PairingManager:
    """Manages the BLE pairing state machine.

    The pairing manager generates pairing codes, verifies user-entered codes,
    generates authentication tokens, and controls LED feedback through
    callbacks to the LED controller.

    Usage:
        pairing = PairingManager(robot_state)
        pairing.on_state_changed = update_led  # LED controller callback
        pairing.on_paired = handle_paired  # post-pairing callback

        # When app connects via BLE:
        await pairing.on_device_connected("AA:BB:CC:DD:EE:FF")

        # When user enters pairing code via BLE write:
        await pairing.verify_code("042917")
    """

    def __init__(self, robot_state: RobotState) -> None:
        """Initialize the pairing manager.

        Args:
            robot_state: Shared robot state. Pairing phase and token
                         are read/written here.
        """
        self._robot_state = robot_state
        self._timeout_task: Optional[asyncio.Task] = None
        self._failure_reset_task: Optional[asyncio.Task] = None
        self._max_code_attempts: int = 3
        self._code_attempts: int = 0

        # Callbacks
        self.on_state_changed: Optional[Callable[[int], None]] = None
        """Called when pairing state changes. Arg is LED state ID (0-8)."""

        self.on_paired: Optional[Callable[[str], None]] = None
        """Called on successful pairing. Arg is pairing token."""

        self.on_pairing_failed: Optional[Callable[[], None]] = None
        """Called on pairing failure (wrong code, timeout)."""

    def _generate_pairing_code(self) -> str:
        """Generate a cryptographically random 6-digit pairing code.

        Returns:
            Zero-padded 6-digit string (e.g., "042917").
        """
        code = secrets.randbelow(10 ** BLE_PAIRING_CODE_LENGTH)
        return f"{code:0{BLE_PAIRING_CODE_LENGTH}d}"

    def _generate_pairing_token(self) -> str:
        """Generate a cryptographically random pairing token.

        The token is a 32-character hex string (16 bytes of entropy).
        Used for WebSocket authentication after BLE pairing.

        Returns:
            32-character hex string (e.g., "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6").
        """
        return secrets.token_hex(BLE_PAIRING_TOKEN_LENGTH // 2)

    async def _set_state(self, phase: PairingPhase) -> None:
        """Update the pairing state and notify listeners.

        Args:
            phase: New PairingPhase value.
        """
        self._robot_state.pairing.phase = phase
        logger.info(f"Pairing state -> {phase.name} (LED state {phase.value})")

        if self.on_state_changed:
            self.on_state_changed(phase.value)

    async def initialize(self) -> None:
        """Initialize to discoverable state on server startup.

        If the robot was previously paired (token exists), go to COMPLETE.
        Otherwise, start in DISCOVERABLE mode.
        """
        if self._robot_state.pairing.is_paired and self._robot_state.pairing.pairing_token:
            await self._set_state(PairingPhase.COMPLETE)
            logger.info("Robot is already paired, skipping pairing flow")
        else:
            await self._set_state(PairingPhase.DISCOVERABLE)

    async def on_device_connected(self, device_address: str) -> None:
        """Called when a BLE client connects.

        Transitions from DISCOVERABLE to FOUND.

        Args:
            device_address: BLE MAC address of the connecting device.
        """
        self._robot_state.pairing.connected_device_address = device_address
        import time
        self._robot_state.pairing.pairing_started_at = time.time()

        if self._robot_state.pairing.is_paired:
            # Already paired -- client is reconnecting
            logger.info(f"Paired device reconnected: {device_address}")
            return

        await self._set_state(PairingPhase.FOUND)
        self._start_timeout()

    async def on_device_disconnected(self) -> None:
        """Called when a BLE client disconnects.

        If pairing was in progress, reset to DISCOVERABLE.
        If already paired, maintain paired state.
        """
        self._cancel_timeout()

        if not self._robot_state.pairing.is_paired:
            await self._set_state(PairingPhase.DISCOVERABLE)
            self._robot_state.pairing.connected_device_address = None
            logger.info("Unpaired device disconnected, returning to discoverable")

    async def start_pairing(self) -> str:
        """Begin the pairing process.

        Called when the user taps "Pair This Robot" in the app.
        Generates a pairing code and transitions to AWAITING_CODE.

        Returns:
            The generated 6-digit pairing code.
        """
        await self._set_state(PairingPhase.PAIRING)
        await asyncio.sleep(0.5)  # Brief visual pause for double-blink

        # Generate code
        code = self._generate_pairing_code()
        self._robot_state.pairing.pairing_code = code
        self._code_attempts = 0

        await self._set_state(PairingPhase.AWAITING_CODE)

        logger.info(f"Pairing code generated: {code}")
        # In production, this code would be displayed on the robot's screen
        # or communicated via a pre-loaded card

        return code

    async def verify_code(self, entered_code: str) -> bool:
        """Verify the pairing code entered by the user.

        Args:
            entered_code: The 6-digit code entered in the app.

        Returns:
            True if the code matches, False otherwise.
        """
        await self._set_state(PairingPhase.VERIFYING)
        self._code_attempts += 1

        # Simulate verification delay (in production, this is instant)
        await asyncio.sleep(1.0)

        expected = self._robot_state.pairing.pairing_code
        if entered_code == expected:
            return await self._on_code_accepted()
        else:
            return await self._on_code_rejected()

    async def _on_code_accepted(self) -> bool:
        """Handle successful code verification.

        Generates a pairing token and transitions to SUCCESS.

        Returns:
            True (always, since the code was accepted).
        """
        self._cancel_timeout()

        # Generate token
        token = self._generate_pairing_token()
        self._robot_state.pairing.pairing_token = token
        self._robot_state.pairing.is_paired = True

        await self._set_state(PairingPhase.SUCCESS)

        logger.info(f"Pairing successful. Token: {token[:8]}...")

        if self.on_paired:
            self.on_paired(token)

        return True

    async def _on_code_rejected(self) -> bool:
        """Handle incorrect code entry.

        After max attempts, transitions to FAILED.
        Otherwise, returns to AWAITING_CODE for retry.

        Returns:
            False (always, since the code was rejected).
        """
        logger.warning(
            f"Pairing code rejected (attempt {self._code_attempts}/{self._max_code_attempts})"
        )

        if self._code_attempts >= self._max_code_attempts:
            await self._on_pairing_failed()
        else:
            # Return to awaiting code for retry
            await self._set_state(PairingPhase.AWAITING_CODE)

        return False

    async def _on_pairing_failed(self) -> None:
        """Handle pairing failure.

        Transitions to FAILED state with red LED flashes,
        then resets to DISCOVERABLE after 3 seconds.
        """
        self._cancel_timeout()

        await self._set_state(PairingPhase.FAILED)

        if self.on_pairing_failed:
            self.on_pairing_failed()

        # Reset to discoverable after delay
        self._failure_reset_task = asyncio.create_task(self._delayed_reset())

    async def _delayed_reset(self) -> None:
        """Wait 3 seconds after failure, then reset to discoverable."""
        await asyncio.sleep(3.0)
        self._robot_state.pairing.reset()
        await self._set_state(PairingPhase.DISCOVERABLE)

    async def transition_to_wifi_setup(self) -> None:
        """Transition to WiFi setup phase after successful pairing.

        Called by the main server when the app navigates to WiFi setup screen.
        """
        if self._robot_state.pairing.phase == PairingPhase.SUCCESS:
            await self._set_state(PairingPhase.WIFI_SETUP)

    async def complete_setup(self) -> None:
        """Transition to complete state after WiFi setup (or skip).

        Called when the setup flow is finished.
        """
        await self._set_state(PairingPhase.COMPLETE)
        self._cancel_timeout()

    def _start_timeout(self) -> None:
        """Start the pairing timeout timer (2 minutes).

        If pairing is not completed within the timeout, reset to discoverable.
        """
        self._cancel_timeout()
        self._timeout_task = asyncio.create_task(self._timeout_handler())

    def _cancel_timeout(self) -> None:
        """Cancel the pairing timeout timer."""
        if self._timeout_task and not self._timeout_task.done():
            self._timeout_task.cancel()

    async def _timeout_handler(self) -> None:
        """Handle pairing timeout.

        After BLE_PAIRING_TIMEOUT_S seconds without completion, reset.
        """
        try:
            await asyncio.sleep(BLE_PAIRING_TIMEOUT_S)
            logger.warning("Pairing timed out, resetting to discoverable")
            self._robot_state.pairing.reset()
            await self._set_state(PairingPhase.DISCOVERABLE)
        except asyncio.CancelledError:
            pass

    def get_stored_token(self) -> Optional[str]:
        """Get the stored pairing token for WebSocket authentication.

        Returns:
            The pairing token if paired, None otherwise.
        """
        if self._robot_state.pairing.is_paired:
            return self._robot_state.pairing.pairing_token
        return None

    def validate_token(self, token: str) -> bool:
        """Validate a pairing token for WebSocket authentication.

        Args:
            token: Token provided in WebSocket handshake header.

        Returns:
            True if the token matches the stored pairing token.
        """
        stored = self.get_stored_token()
        if stored is None:
            return False
        return secrets.compare_digest(token, stored)
