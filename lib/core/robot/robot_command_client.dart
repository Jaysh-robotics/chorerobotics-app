import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum RobotCommandConnectionStatus { disconnected, connecting, connected, error }

class RobotCommandAck {
  final String commandId;
  final String type;
  final String status;
  final DateTime receivedAt;
  final Map<String, dynamic> payload;

  const RobotCommandAck({
    required this.commandId,
    required this.type,
    required this.status,
    required this.receivedAt,
    required this.payload,
  });

  factory RobotCommandAck.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    final payloadMap = payload is Map<String, dynamic>
        ? payload
        : const <String, dynamic>{};
    return RobotCommandAck(
      commandId:
          payloadMap['command_id']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'command_ack',
      status: payloadMap['status']?.toString() ?? 'received',
      receivedAt: DateTime.now(),
      payload: payloadMap,
    );
  }
}

class RobotCommandClient extends ChangeNotifier {
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  RobotCommandConnectionStatus _status =
      RobotCommandConnectionStatus.disconnected;
  String? _errorMessage;
  RobotCommandAck? _lastAck;
  String? _lastSentType;
  String? _lastInboundRaw;
  String _serverUrl = 'ws://192.168.1.100:8765/ws';
  int _sequence = 0;
  int _sentCount = 0;
  int _ackCount = 0;
  bool _mowerScheduleEnabled = true;

  RobotCommandConnectionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  RobotCommandAck? get lastAck => _lastAck;
  String? get lastSentType => _lastSentType;
  String? get lastInboundRaw => _lastInboundRaw;
  String get serverUrl => _serverUrl;
  int get sentCount => _sentCount;
  int get ackCount => _ackCount;
  bool get mowerScheduleEnabled => _mowerScheduleEnabled;
  bool get isConnected => _status == RobotCommandConnectionStatus.connected;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  void setServerUrl(String url) {
    final normalized = url.trim();
    if (normalized.isEmpty || normalized == _serverUrl) return;
    _serverUrl = normalized;
    notifyListeners();
  }

  Future<void> connect([String? url]) async {
    if (url != null) {
      setServerUrl(url);
    }
    await disconnect();
    _setStatus(RobotCommandConnectionStatus.connecting);

    try {
      final uri = Uri.parse(_serverUrl);
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _subscription = channel.stream.listen(
        _handleMessage,
        onError: (Object error) {
          _errorMessage = error.toString();
          _setStatus(RobotCommandConnectionStatus.error);
        },
        onDone: () {
          if (_status != RobotCommandConnectionStatus.disconnected) {
            _setStatus(RobotCommandConnectionStatus.disconnected);
          }
        },
      );
      await channel.ready;
      _setStatus(RobotCommandConnectionStatus.connected);
      sendPing();
    } catch (error) {
      await _subscription?.cancel();
      _subscription = null;
      await _channel?.sink.close();
      _channel = null;
      _errorMessage = error.toString();
      _setStatus(RobotCommandConnectionStatus.error);
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _setStatus(RobotCommandConnectionStatus.disconnected);
  }

  void sendPing() {
    _send('ping', const {});
  }

  void sendDriveCommand({required double linearX, required double angularZ}) {
    _send('drive_command', {
      'linear_x': _round(linearX),
      'angular_z': _round(angularZ),
    });
  }

  void sendDirectionalCommand(String direction) {
    final values = switch (direction) {
      'forward' => (linearX: 1.0, angularZ: 0.0),
      'backward' => (linearX: -1.0, angularZ: 0.0),
      'left' => (linearX: 0.0, angularZ: -1.0),
      'right' => (linearX: 0.0, angularZ: 1.0),
      _ => (linearX: 0.0, angularZ: 0.0),
    };
    _send('drive_command', {
      'direction': direction,
      'linear_x': values.linearX,
      'angular_z': values.angularZ,
    });
  }

  void sendBladeCommand(bool enabled) {
    _send('blade_control', {'enabled': enabled});
  }

  String? sendAttachmentDetect() => _send('attachment_detect', const {});

  String? sendAttachmentSelected(
    String attachment, {
    required bool supported,
    String? serialNumber,
  }) {
    return _send('attachment_select', {
      'attachment': attachment,
      'supported': supported,
      if (serialNumber != null && serialNumber.isNotEmpty)
        'serial_number': serialNumber,
    });
  }

  void sendMowerConfiguration({
    required int stripeAngleDegrees,
    required String pattern,
    required int cutHeightMm,
    required String zoneId,
  }) {
    _send('mower_config_update', {
      'stripe_angle_degrees': stripeAngleDegrees,
      'pattern': pattern,
      'cut_height_mm': cutHeightMm,
      'zone_id': zoneId,
    });
  }

  void sendScheduleSet({
    required String scheduleId,
    required int hour,
    required int minute,
    required String period,
    required List<int> days,
    required Map<String, dynamic> taskParameters,
    bool? enabled,
  }) {
    _send('schedule_set', {
      'schedule_id': scheduleId,
      'hour': hour,
      'minute': minute,
      'period': period,
      'days': days,
      'task_type': 'mow',
      'task_parameters': taskParameters,
      'enabled': ?enabled,
    });
  }

  void setMowerScheduleEnabled(bool enabled) {
    _mowerScheduleEnabled = enabled;
    // shortcut: the redesigned dashboard uses a sample schedule until cloud schedules are integrated.
    sendScheduleSet(
      scheduleId: 'mower-weekly',
      hour: 8,
      minute: 0,
      period: 'AM',
      days: const [3],
      taskParameters: const {'pattern': 'straight'},
      enabled: enabled,
    );
    notifyListeners();
  }

  void sendTaskStart({
    required String taskId,
    required String taskType,
    required String zoneId,
    required String zoneName,
    required double totalAreaSqM,
    Map<String, dynamic> parameters = const {},
  }) {
    _send('task_start', {
      'task_id': taskId,
      'task_type': taskType,
      'zone_id': zoneId,
      'zone_name': zoneName,
      'total_area_sq_m': totalAreaSqM,
      'parameters': parameters,
    });
  }

  void sendTaskPause({String? taskId}) {
    final payload = <String, dynamic>{};
    if (taskId != null) payload['task_id'] = taskId;
    _send('task_pause', payload);
  }

  void sendTaskResume({String? taskId}) {
    final payload = <String, dynamic>{};
    if (taskId != null) payload['task_id'] = taskId;
    _send('task_resume', payload);
  }

  void sendTaskStop({String? taskId, String reason = 'user_requested'}) {
    final payload = <String, dynamic>{'reason': reason};
    if (taskId != null) payload['task_id'] = taskId;
    _send('task_stop', payload);
  }

  void sendDock() {
    _send('dock', const {});
  }

  void sendEStop() {
    _send('estop', {'action': 'activate'});
  }

  String? _send(String type, Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null || !isConnected) {
      debugPrint('[RobotCommandClient] offline preview skipped: $type');
      return null;
    }

    final id = 'app-${DateTime.now().millisecondsSinceEpoch}-${++_sequence}';
    final message = {
      'type': type,
      'id': id,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': payload,
    };
    channel.sink.add(jsonEncode(message));
    _lastSentType = type;
    _sentCount += 1;
    notifyListeners();
    return id;
  }

  void _handleMessage(dynamic raw) {
    try {
      _lastInboundRaw = raw.toString();
      final decoded = jsonDecode(raw.toString());
      if (decoded is! Map<String, dynamic>) return;
      _messageController.add(decoded);
      final type = decoded['type']?.toString();
      if (type == 'command_ack' || type == 'pong') {
        debugPrint('[RobotCommandClient] <- $_lastInboundRaw');
        _lastAck = RobotCommandAck.fromJson(decoded);
        _ackCount += 1;
        _errorMessage = null;
        _setStatus(RobotCommandConnectionStatus.connected);
        return;
      }
      if (type == 'telemetry' ||
          type == 'task_update' ||
          type == 'alert' ||
          type == 'estop_status') {
        _errorMessage = null;
        notifyListeners();
        return;
      }
      debugPrint('[RobotCommandClient] unexpected <- $_lastInboundRaw');
      _errorMessage = 'Unexpected server message: $type';
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Invalid server message: $error';
      notifyListeners();
    }
  }

  void _setStatus(RobotCommandConnectionStatus status) {
    _status = status;
    notifyListeners();
  }

  double _round(double value) => double.parse(value.toStringAsFixed(3));

  @override
  void dispose() {
    final subscription = _subscription;
    final channel = _channel;
    _subscription = null;
    _channel = null;
    unawaited(subscription?.cancel());
    unawaited(channel?.sink.close());
    unawaited(_messageController.close());
    super.dispose();
  }
}
