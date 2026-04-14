"""
WebSocket Connection Authentication.

Validates incoming WebSocket connections using the pairing token
established during the BLE pairing flow. The token is sent as an
HTTP header in the WebSocket upgrade request.

Authentication Flow:
    1. App connects to ws://chorerobot-XXXX.local:8765/ws
    2. App includes X-Pairing-Token header in upgrade request
    3. Server validates token against stored pairing token
    4. If valid: connection accepted
    5. If invalid: HTTP 401 Unauthorized, connection closed

Security Notes:
    - Token comparison uses constant-time comparison (secrets.compare_digest)
      to prevent timing attacks.
    - Tokens are 32-character hex strings (128 bits of entropy).
    - The WebSocket connection is not encrypted (ws://, not wss://)
      because it operates on a local network. For production, consider
      adding TLS with self-signed certificates.
"""

import secrets
import logging
from typing import Optional, Tuple

logger = logging.getLogger(__name__)

# Header name for the pairing token in the WebSocket upgrade request
PAIRING_TOKEN_HEADER = "X-Pairing-Token"

# Header name for the client identifier
CLIENT_ID_HEADER = "X-Client-Id"


class WebSocketAuth:
    """Authenticates incoming WebSocket connections using pairing tokens.

    The WebSocket auth module holds the stored pairing token and validates
    incoming connection requests. It is shared between the WebSocket server
    and the BLE pairing manager.

    Usage:
        auth = WebSocketAuth()
        auth.set_token("a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6")

        # During WebSocket handshake:
        is_valid, client_id = auth.validate_handshake(request_headers)
        if not is_valid:
            return HTTP 401
    """

    def __init__(self) -> None:
        """Initialize with no token (not paired yet)."""
        self._stored_token: Optional[str] = None
        self._connected_clients: dict = {}  # client_id -> connection info

    def set_token(self, token: str) -> None:
        """Store the pairing token generated during BLE pairing.

        Called by the PairingManager after successful pairing.

        Args:
            token: 32-character hex string pairing token.
        """
        self._stored_token = token
        logger.info(f"WebSocket auth token set: {token[:8]}...")

    def has_token(self) -> bool:
        """Check if a pairing token has been set.

        Returns:
            True if the robot has been paired and a token exists.
        """
        return self._stored_token is not None

    def validate_handshake(
        self, headers: dict
    ) -> Tuple[bool, Optional[str]]:
        """Validate the pairing token from a WebSocket upgrade request.

        Uses constant-time comparison to prevent timing attacks.

        Args:
            headers: Dict of HTTP headers from the upgrade request.
                     Expected to contain X-Pairing-Token and X-Client-Id.

        Returns:
            Tuple of (is_valid, client_id). client_id is None if invalid.
        """
        if not self.has_token():
            logger.warning("WebSocket connection rejected: no pairing token stored")
            return False, None

        provided_token = headers.get(PAIRING_TOKEN_HEADER, "")
        client_id = headers.get(CLIENT_ID_HEADER, "unknown")

        if not provided_token:
            logger.warning("WebSocket connection rejected: no token in headers")
            return False, None

        # Constant-time comparison
        is_valid = secrets.compare_digest(provided_token, self._stored_token)

        if is_valid:
            logger.info(f"WebSocket connection authenticated: client={client_id}")
        else:
            logger.warning(f"WebSocket connection rejected: invalid token from {client_id}")

        return is_valid, client_id if is_valid else None

    def register_client(self, client_id: str, connection_info: dict) -> None:
        """Register a successfully authenticated WebSocket client.

        Args:
            client_id: Unique identifier from X-Client-Id header.
            connection_info: Dict with connection metadata (address, connected_at, etc.).
        """
        self._connected_clients[client_id] = connection_info
        logger.info(f"WebSocket client registered: {client_id}")

    def unregister_client(self, client_id: str) -> None:
        """Unregister a disconnected WebSocket client.

        Args:
            client_id: Client identifier to remove.
        """
        self._connected_clients.pop(client_id, None)
        logger.info(f"WebSocket client unregistered: {client_id}")

    @property
    def connected_count(self) -> int:
        """Number of currently connected WebSocket clients."""
        return len(self._connected_clients)

    def revoke_token(self) -> None:
        """Revoke the current pairing token.

        Called during factory reset or unpairing. All current WebSocket
        connections will be closed on next validation check.
        """
        self._stored_token = None
        self._connected_clients.clear()
        logger.info("WebSocket auth token revoked")
