"""
Firebase Client module.

Provides cloud connectivity for the robot using the Firebase Admin SDK.
The robot pushes telemetry, task history, battery history, and alerts
to Firebase, and listens for commands, zone updates, and firmware metadata.

Components:
    - FirebaseClient: Admin SDK initialization and Firestore/RTDB/Storage access
    - TelemetryUploader: Periodic upload of telemetry to RTDB and Firestore
    - CommandListener: Real-time listener for cloud commands from the app
"""

from .client import FirebaseClient
from .telemetry_uploader import TelemetryUploader
from .command_listener import CommandListener

__all__ = ["FirebaseClient", "TelemetryUploader", "CommandListener"]
