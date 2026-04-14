"""
ROS2 Bridge module.

Bridges the robot server to the ROS2 autonomy stack. Subscribes to
sensor topics for telemetry data and publishes commands from the app
to the robot's actuators.

Components:
    - RosTelemetrySubscriber: Subscribes to sensor topics and updates
      the shared TelemetrySnapshot.
    - RosCommandPublisher: Publishes drive commands, task commands,
      E-Stop, and other controls to ROS2 topics.

ROS2 Dependencies:
    - rclpy (ROS2 Python client library)
    - std_msgs, geometry_msgs, sensor_msgs, nav_msgs
    - diagnostic_msgs
    - chorerobot_msgs (custom messages)
"""

from .subscriber import RosTelemetrySubscriber
from .publisher import RosCommandPublisher

__all__ = ["RosTelemetrySubscriber", "RosCommandPublisher"]
