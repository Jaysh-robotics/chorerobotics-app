"""
WiFi WebSocket Server module.

Implements the WebSocket server that the Flutter app connects to when
on the same LAN as the robot. Provides higher-bandwidth communication
than BLE with JSON-based message protocol.

Architecture:
    mDNS (Avahi) -- advertises chorerobot-XXXX.local:8765
        |
    WebSocketServer (websocket_server.py) -- accepts connections
        |
    MessageProtocol (protocol.py) -- serialize/deserialize JSON messages
        |
    WebSocketAuth (auth.py) -- validates pairing token on handshake
"""

from .websocket_server import WebSocketServer
from .protocol import MessageProtocol
from .auth import WebSocketAuth

__all__ = ["WebSocketServer", "MessageProtocol", "WebSocketAuth"]
