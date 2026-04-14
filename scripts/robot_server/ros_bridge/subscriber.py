"""
ROS2 Telemetry Subscriber.

Subscribes to ROS2 sensor topics and updates the shared TelemetrySnapshot
with the latest data. Each topic has its own callback that updates the
relevant fields in the snapshot.

Subscribed Topics:
    /battery/state        -- sensor_msgs/BatteryState        @ 1 Hz
    /odom                 -- nav_msgs/Odometry                @ 10 Hz
    /imu/data             -- sensor_msgs/Imu                  @ 50 Hz
    /gps/fix              -- sensor_msgs/NavSatFix            @ 5 Hz
    /gps/rtk_status       -- std_msgs/String                  @ 1 Hz
    /motor_speeds         -- chorerobot_msgs/MotorSpeeds      @ 10 Hz
    /system/temperature   -- sensor_msgs/Temperature          @ 0.2 Hz
    /attachment/state     -- chorerobot_msgs/AttachmentState   @ 1 Hz
    /task/progress        -- chorerobot_msgs/TaskProgress      @ 1 Hz
    /diagnostics          -- diagnostic_msgs/DiagnosticArray   @ 1 Hz
    /estop/state          -- std_msgs/Bool                     @ event
"""

import logging
import math
from typing import Optional, Callable

from ..models.telemetry import TelemetrySnapshot
from ..models.robot_state import RobotState, TaskState
from ..config import (
    ROS2_NODE_NAME,
    ROS2_TOPIC_BATTERY_STATE,
    ROS2_TOPIC_ODOMETRY,
    ROS2_TOPIC_IMU,
    ROS2_TOPIC_GPS_FIX,
    ROS2_TOPIC_RTK_STATUS,
    ROS2_TOPIC_MOTOR_SPEEDS,
    ROS2_TOPIC_SYSTEM_TEMP,
    ROS2_TOPIC_ATTACHMENT_STATE,
    ROS2_TOPIC_TASK_PROGRESS,
    ROS2_TOPIC_DIAGNOSTICS,
    ROS2_TOPIC_ESTOP_STATE,
    ROS2_QOS_RELIABLE_DEPTH,
    ROS2_QOS_BEST_EFFORT_DEPTH,
)

logger = logging.getLogger(__name__)


class RosTelemetrySubscriber:
    """Subscribes to ROS2 sensor topics and populates telemetry data.

    Creates subscriptions for all sensor topics on the ROS2 node.
    Each subscription callback updates the relevant fields in the
    shared TelemetrySnapshot. The snapshot is then read by the BLE,
    WebSocket, and Firebase modules at their respective output rates.

    Usage:
        # Initialize within a ROS2 node
        subscriber = RosTelemetrySubscriber(node, telemetry, robot_state)
        subscriber.start()

        # The telemetry snapshot is now being updated by ROS2 callbacks
    """

    def __init__(
        self,
        node: "Any",  # rclpy.node.Node
        telemetry: TelemetrySnapshot,
        robot_state: RobotState,
    ) -> None:
        """Initialize the telemetry subscriber.

        Args:
            node: The ROS2 node to create subscriptions on.
            telemetry: Shared telemetry snapshot to update.
            robot_state: Shared robot state for E-Stop and task tracking.
        """
        self._node = node
        self._telemetry = telemetry
        self._robot_state = robot_state
        self._subscriptions = []

        # Callback for E-Stop hardware events
        self.on_hardware_estop: Optional[Callable[[bool], None]] = None

    def start(self) -> None:
        """Create all ROS2 subscriptions.

        Subscribes to each sensor topic with the appropriate QoS profile
        and callback function.
        """
        # TODO: implement with actual ROS2 subscriptions
        # from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy
        #
        # reliable_qos = QoSProfile(
        #     reliability=ReliabilityPolicy.RELIABLE,
        #     history=HistoryPolicy.KEEP_LAST,
        #     depth=ROS2_QOS_RELIABLE_DEPTH,
        # )
        # best_effort_qos = QoSProfile(
        #     reliability=ReliabilityPolicy.BEST_EFFORT,
        #     history=HistoryPolicy.KEEP_LAST,
        #     depth=ROS2_QOS_BEST_EFFORT_DEPTH,
        # )

        logger.info("Creating ROS2 telemetry subscriptions")

        # self._subscriptions.append(
        #     self._node.create_subscription(
        #         BatteryState,
        #         ROS2_TOPIC_BATTERY_STATE,
        #         self._on_battery_state,
        #         reliable_qos,
        #     )
        # )
        # ... repeat for all topics

    def stop(self) -> None:
        """Destroy all ROS2 subscriptions."""
        for sub in self._subscriptions:
            self._node.destroy_subscription(sub)
        self._subscriptions.clear()
        logger.info("ROS2 telemetry subscriptions destroyed")

    # =========================================================================
    # Subscription Callbacks
    # =========================================================================

    def _on_battery_state(self, msg: "Any") -> None:
        """Handle battery state message from /battery/state.

        Updates: battery.percent, battery.voltage, battery.current_amps,
                 battery.temp_c, battery.health_pct, battery.cycles

        Args:
            msg: sensor_msgs/BatteryState message.
        """
        # TODO: implement
        # self._telemetry.battery.percent = msg.percentage * 100.0
        # self._telemetry.battery.voltage = msg.voltage
        # self._telemetry.battery.current_amps = msg.current
        # self._telemetry.battery.temp_c = msg.temperature
        # self._telemetry.battery.health_pct = msg.capacity / msg.design_capacity * 100
        # self._telemetry.battery.cycles = int(msg.charge)  # overloaded field
        pass

    def _on_odometry(self, msg: "Any") -> None:
        """Handle odometry message from /odom.

        Updates: motion.speed_ms (from twist.linear.x magnitude)

        Args:
            msg: nav_msgs/Odometry message.
        """
        # TODO: implement
        # vx = msg.twist.twist.linear.x
        # vy = msg.twist.twist.linear.y
        # self._telemetry.motion.speed_ms = math.sqrt(vx**2 + vy**2)
        pass

    def _on_imu(self, msg: "Any") -> None:
        """Handle IMU data message from /imu/data.

        Updates: motion.heading_deg (from quaternion orientation)

        The IMU provides orientation as a quaternion which is converted
        to Euler angles. The yaw component gives the compass heading.

        Args:
            msg: sensor_msgs/Imu message.
        """
        # TODO: implement
        # q = msg.orientation
        # # Convert quaternion to yaw (heading)
        # siny_cosp = 2 * (q.w * q.z + q.x * q.y)
        # cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z)
        # yaw_rad = math.atan2(siny_cosp, cosy_cosp)
        # heading_deg = math.degrees(yaw_rad) % 360.0
        # self._telemetry.motion.heading_deg = heading_deg
        pass

    def _on_gps_fix(self, msg: "Any") -> None:
        """Handle GPS fix message from /gps/fix.

        Updates: gps.latitude, gps.longitude, gps.satellite_count,
                 gps.accuracy_cm

        Args:
            msg: sensor_msgs/NavSatFix message.
        """
        # TODO: implement
        # self._telemetry.gps.latitude = msg.latitude
        # self._telemetry.gps.longitude = msg.longitude
        # # Accuracy from covariance matrix (position_covariance[0] = variance in meters)
        # accuracy_m = math.sqrt(msg.position_covariance[0])
        # self._telemetry.gps.accuracy_cm = accuracy_m * 100.0
        pass

    def _on_rtk_status(self, msg: "Any") -> None:
        """Handle RTK status message from /gps/rtk_status.

        Updates: gps.rtk_status

        Args:
            msg: std_msgs/String message with value 'none', 'single', 'float', or 'fix'.
        """
        # TODO: implement
        # self._telemetry.gps.rtk_status = msg.data
        pass

    def _on_motor_speeds(self, msg: "Any") -> None:
        """Handle motor speeds message from /motor_speeds.

        Updates: motors.fl_rpm, motors.fr_rpm, motors.rl_rpm, motors.rr_rpm

        Args:
            msg: chorerobot_msgs/MotorSpeeds message.
        """
        # TODO: implement
        # self._telemetry.motors.fl_rpm = msg.fl_rpm
        # self._telemetry.motors.fr_rpm = msg.fr_rpm
        # self._telemetry.motors.rl_rpm = msg.rl_rpm
        # self._telemetry.motors.rr_rpm = msg.rr_rpm
        pass

    def _on_system_temperature(self, msg: "Any") -> None:
        """Handle system temperature message from /system/temperature.

        Updates: system.temp_c

        Args:
            msg: sensor_msgs/Temperature message.
        """
        # TODO: implement
        # self._telemetry.system.temp_c = msg.temperature
        pass

    def _on_attachment_state(self, msg: "Any") -> None:
        """Handle attachment state message from /attachment/state.

        Updates: system.attachment_type, robot_state.attachment_type

        Args:
            msg: chorerobot_msgs/AttachmentState message.
        """
        # TODO: implement
        # self._telemetry.system.attachment_type = msg.type
        # self._robot_state.attachment_type = msg.type
        pass

    def _on_task_progress(self, msg: "Any") -> None:
        """Handle task progress message from /task/progress.

        Updates the shared TaskState in robot_state.

        Args:
            msg: chorerobot_msgs/TaskProgress message.
        """
        # TODO: implement
        # task = self._robot_state.task
        # task.task_id = msg.task_id
        # task.task_type = msg.task_type
        # task.zone_id = msg.zone_id
        # task.zone_name = msg.zone_name
        # task.status = msg.status
        # task.progress_pct = msg.progress_pct
        # task.area_completed_sq_m = msg.area_completed_sq_m
        # task.area_total_sq_m = msg.area_total_sq_m
        # task.elapsed_seconds = msg.elapsed_seconds
        # task.battery_used_pct = msg.battery_used_pct
        # task.fail_reason = msg.fail_reason if msg.fail_reason else None
        # task.can_resume = msg.can_resume
        pass

    def _on_diagnostics(self, msg: "Any") -> None:
        """Handle diagnostics message from /diagnostics.

        Processes diagnostic statuses and creates alerts for faults.

        Args:
            msg: diagnostic_msgs/DiagnosticArray message.
        """
        # TODO: implement
        # for status in msg.status:
        #     if status.level >= DiagnosticStatus.WARN:
        #         # Create alert
        #         pass
        pass

    def _on_estop_state(self, msg: "Any") -> None:
        """Handle hardware E-Stop state from /estop/state.

        This is the HARDWARE E-Stop button on the robot itself
        (separate from software E-Stop sent via app).

        Args:
            msg: std_msgs/Bool message. True = E-Stop active.
        """
        # TODO: implement
        # if msg.data:
        #     logger.warning("Hardware E-Stop activated")
        #     if self.on_hardware_estop:
        #         self.on_hardware_estop(True)
        # else:
        #     logger.info("Hardware E-Stop released")
        #     if self.on_hardware_estop:
        #         self.on_hardware_estop(False)
        pass
