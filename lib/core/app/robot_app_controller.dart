import 'dart:async';

import 'package:flutter/foundation.dart';

import '../robot/robot_command_client.dart';

enum RobotTaskStatus { idle, running, paused, completed, cancelled, stopped }

@immutable
class MowerSchedule {
  const MowerSchedule({
    required this.hour,
    required this.minute,
    required this.period,
    required this.days,
  });

  final int hour;
  final int minute;
  final String period;
  final Set<int> days;

  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
}

class RobotAppController extends ChangeNotifier {
  RobotAppController(this.commandClient) {
    _messageSubscription = commandClient.messages.listen(_handleServerMessage);
  }

  final RobotCommandClient commandClient;
  late final StreamSubscription<Map<String, dynamic>> _messageSubscription;

  String selectedAttachment = 'mower';
  double stripeAngle = 45;
  String stripePattern = 'straight';
  double cutHeightMm = 50;
  String zoneId = 'zone_2';
  String zoneName = 'Zone 2';
  MowerSchedule? schedule;

  RobotTaskStatus taskStatus = RobotTaskStatus.idle;
  String? taskId;
  double progressPercent = 0;
  double completedAreaSqM = 0;
  double totalAreaSqM = 142;
  int elapsedSeconds = 0;
  double batteryUsedPercent = 0;

  bool get hasActiveTask =>
      taskStatus == RobotTaskStatus.running ||
      taskStatus == RobotTaskStatus.paused;

  String get formattedElapsed {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void selectAttachment(String attachment, {required bool supported}) {
    selectedAttachment = attachment;
    commandClient.sendAttachmentSelected(attachment, supported: supported);
    notifyListeners();
  }

  void setStripeAngle(double value, {bool send = false}) {
    stripeAngle = value;
    if (send) _sendMowerConfiguration();
    notifyListeners();
  }

  void setStripePattern(String value) {
    stripePattern = value;
    _sendMowerConfiguration();
    notifyListeners();
  }

  void setCutHeight(double value, {bool send = false}) {
    cutHeightMm = value;
    if (send) _sendMowerConfiguration();
    notifyListeners();
  }

  void setZone(String id, String name) {
    zoneId = id;
    zoneName = name;
    _sendMowerConfiguration();
    notifyListeners();
  }

  void saveSchedule(MowerSchedule value) {
    schedule = value;
    commandClient.sendScheduleSet(
      scheduleId: 'mower-weekly',
      hour: value.hour,
      minute: value.minute,
      period: value.period,
      days: value.days.toList()..sort(),
      taskParameters: mowerParameters,
    );
    notifyListeners();
  }

  void startMowing() {
    taskId = 'mow-${DateTime.now().millisecondsSinceEpoch}';
    taskStatus = RobotTaskStatus.running;
    progressPercent = 0;
    completedAreaSqM = 0;
    elapsedSeconds = 0;
    batteryUsedPercent = 0;
    commandClient.sendTaskStart(
      taskId: taskId!,
      taskType: 'mow',
      zoneId: zoneId,
      zoneName: zoneName,
      totalAreaSqM: totalAreaSqM,
      parameters: mowerParameters,
    );
    notifyListeners();
  }

  void pauseTask() {
    if (taskStatus != RobotTaskStatus.running) return;
    commandClient.sendTaskPause(taskId: taskId);
    taskStatus = RobotTaskStatus.paused;
    notifyListeners();
  }

  void resumeTask() {
    if (taskStatus != RobotTaskStatus.paused) return;
    commandClient.sendTaskResume(taskId: taskId);
    taskStatus = RobotTaskStatus.running;
    notifyListeners();
  }

  void cancelTask() {
    commandClient.sendTaskStop(taskId: taskId, reason: 'user_cancelled');
    taskStatus = RobotTaskStatus.cancelled;
    notifyListeners();
  }

  void emergencyStop() {
    if (hasActiveTask) {
      commandClient.sendTaskStop(taskId: taskId, reason: 'emergency_stop');
    }
    commandClient.sendEStop();
    taskStatus = RobotTaskStatus.cancelled;
    notifyListeners();
  }

  Map<String, dynamic> get mowerParameters => {
    'stripe_angle_degrees': stripeAngle.round(),
    'pattern': stripePattern,
    'cut_height_mm': cutHeightMm.round(),
  };

  void _sendMowerConfiguration() {
    commandClient.sendMowerConfiguration(
      stripeAngleDegrees: stripeAngle.round(),
      pattern: stripePattern,
      cutHeightMm: cutHeightMm.round(),
      zoneId: zoneId,
    );
  }

  void _handleServerMessage(Map<String, dynamic> message) {
    if (message['type'] != 'task_update') return;
    final rawPayload = message['payload'];
    if (rawPayload is! Map) return;
    final payload = Map<String, dynamic>.from(rawPayload);
    if (payload['task_id']?.toString() != taskId) return;

    progressPercent = _asDouble(payload['progress_pct']);
    completedAreaSqM = _asDouble(payload['area_completed_sq_m']);
    totalAreaSqM = _asDouble(
      payload['area_total_sq_m'],
      fallback: totalAreaSqM,
    );
    elapsedSeconds = _asInt(payload['elapsed_seconds']);
    batteryUsedPercent = _asDouble(payload['battery_used_pct']);
    taskStatus = switch (payload['status']?.toString()) {
      'running' => RobotTaskStatus.running,
      'paused' => RobotTaskStatus.paused,
      'completed' => RobotTaskStatus.completed,
      'cancelled' => RobotTaskStatus.cancelled,
      'stopped' => RobotTaskStatus.stopped,
      _ => taskStatus,
    };
    notifyListeners();
  }

  double _asDouble(Object? value, {double fallback = 0}) =>
      value is num ? value.toDouble() : fallback;

  int _asInt(Object? value) => value is num ? value.toInt() : 0;

  @override
  void dispose() {
    _messageSubscription.cancel();
    super.dispose();
  }
}
