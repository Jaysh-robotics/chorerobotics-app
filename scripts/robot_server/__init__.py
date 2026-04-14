"""
ChoreRobotics Robot Onboard Server

The robot server runs on a Jetson Nano and provides three communication
interfaces to the Flutter mobile app:

1. BLE GATT Server -- phone discovers and pairs with robot over Bluetooth
2. WiFi WebSocket Server -- high-bandwidth local connection on same LAN
3. Firebase Client -- cloud connectivity for remote access and telemetry upload

Additionally, it integrates with:
4. LED Controller -- visual feedback during pairing and operation
5. ROS2 Bridge -- communication with the robot's autonomy stack (nav2, sensors)

Architecture:
    App <--BLE/WiFi--> Robot Server <--ROS2--> Autonomy Stack
                            |
                            +--> Firebase Cloud (telemetry, commands, history)
                            +--> LED Strip (visual feedback)
"""

__version__ = "0.1.0"
__author__ = "ChoreRobotics"
