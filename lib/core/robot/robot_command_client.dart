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
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  RobotCommandConnectionStatus _status =
      RobotCommandConnectionStatus.disconnected;
  String? _errorMessage;
  RobotCommandAck? _lastAck;
  String? _lastSentType;
  String? _lastInboundRaw;
  int _sequence = 0;
  int _sentCount = 0;
  int _ackCount = 0;

  RobotCommandConnectionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  RobotCommandAck? get lastAck => _lastAck;
  String? get lastSentType => _lastSentType;
  String? get lastInboundRaw => _lastInboundRaw;
  int get sentCount => _sentCount;
  int get ackCount => _ackCount;
  bool get isConnected => _status == RobotCommandConnectionStatus.connected;

  Future<void> connect(String url) async {
    await disconnect();
    _setStatus(RobotCommandConnectionStatus.connecting);

    try {
      final uri = Uri.parse(url.trim());
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
      _setStatus(RobotCommandConnectionStatus.connected);
      sendPing();
    } catch (error) {
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

  void sendTaskCommand(String command) {
    _send('task_command', {'command': command});
  }

  void sendEStop() {
    _send('estop', {'activate': true});
  }

  void _send(String type, Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null || !isConnected) {
      _errorMessage = 'Not connected to command server.';
      _setStatus(RobotCommandConnectionStatus.error);
      return;
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
  }

  void _handleMessage(dynamic raw) {
    try {
      _lastInboundRaw = raw.toString();
      debugPrint('[RobotCommandClient] <- $_lastInboundRaw');
      final decoded = jsonDecode(raw.toString());
      if (decoded is! Map<String, dynamic>) return;
      final type = decoded['type']?.toString();
      if (type == 'command_ack' || type == 'pong') {
        _lastAck = RobotCommandAck.fromJson(decoded);
        _ackCount += 1;
        _errorMessage = null;
        _setStatus(RobotCommandConnectionStatus.connected);
        return;
      }
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
    unawaited(disconnect());
    super.dispose();
  }
}
