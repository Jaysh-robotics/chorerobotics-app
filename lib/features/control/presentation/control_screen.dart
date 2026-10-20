import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/robot/robot_command_client.dart';
import '../../../core/widgets/joystick_widget.dart';
import '../../../core/widgets/compass_widget.dart';
import '../../../core/widgets/brand_badge.dart';
import '../../../core/widgets/estop_button.dart';

class ControlScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ControlScreen({super.key, this.onBack});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final _serverUrlCtrl = TextEditingController();
  late RobotCommandClient _commandClient;
  bool _listeningToCommandClient = false;
  bool _bladeOn = false;
  double _speed = 0.8;
  double _heading = 0;
  DateTime _lastDriveSend = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final client = context.read<RobotCommandClient>();
    if (_listeningToCommandClient && identical(_commandClient, client)) return;
    if (_listeningToCommandClient) {
      _commandClient.removeListener(_onCommandClientChanged);
    }
    _commandClient = client;
    _serverUrlCtrl.text = _commandClient.serverUrl;
    _commandClient.addListener(_onCommandClientChanged);
    _listeningToCommandClient = true;
  }

  @override
  void dispose() {
    if (_listeningToCommandClient) {
      _commandClient.removeListener(_onCommandClientChanged);
    }
    _serverUrlCtrl.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _onCommandClientChanged() {
    if (_serverUrlCtrl.text != _commandClient.serverUrl) {
      _serverUrlCtrl.text = _commandClient.serverUrl;
    }
    if (mounted) setState(() {});
  }

  void _sendDriveFromJoystick(double speed, double angle) {
    final now = DateTime.now();
    if (now.difference(_lastDriveSend).inMilliseconds < 120) return;
    _lastDriveSend = now;

    final linearX = speed == 0 ? 0.0 : -speed * _sinY(angle);
    final angularZ = speed == 0 ? 0.0 : speed * _cosX(angle);
    _commandClient.sendDriveCommand(linearX: linearX, angularZ: angularZ);
  }

  double _sinY(double angle) {
    // Joystick angle uses screen coordinates: up is negative Y.
    return double.parse(math.sin(angle).toStringAsFixed(3));
  }

  double _cosX(double angle) =>
      double.parse(math.cos(angle).toStringAsFixed(3));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.bgSecondary,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  // Left: back button + connection + mode
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.portraitUp,
                          ]);
                          widget.onBack?.call();
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.statusGreen,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Local',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const BrandBadge(
                        label: 'MANUAL',
                        variant: BadgeVariant.purple,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Center: speed + heading
                  Row(
                    children: [
                      Column(
                        children: [
                          const Text(
                            'SPEED',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _speed.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                  letterSpacing: -1,
                                ),
                              ),
                              const Text(
                                ' m/s',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        color: AppColors.border,
                      ),
                      Column(
                        children: [
                          const Text(
                            'HEADING',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _heading.round().toString().padLeft(3, '0'),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                  letterSpacing: -1,
                                ),
                              ),
                              const Text(
                                '°',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Right: battery
                  Row(
                    children: [
                      const Icon(
                        PhosphorIconsBold.batteryFull,
                        size: 14,
                        color: AppColors.brandBlue,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '78%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Left: Joystick
                      Container(
                        width: 260,
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Center(
                          child: JoystickWidget(
                            size: 180,
                            label: 'DRIVE',
                            deadzone: 0.1,
                            onSpeedChanged: (speed, angle) {
                              // Speed is 0.0-1.0 proportional to displacement
                              // Max robot speed = 2.0 m/s
                              setState(() {
                                _speed = speed * 2.0; // 0-2 m/s
                                if (speed > 0.05) {
                                  // Convert joystick angle to heading (0° = North/Up, 90° = East/Right)
                                  final angleDeg = angle * 180 / math.pi;
                                  _heading =
                                      ((angleDeg + 90) % 360 + 360) % 360;
                                }
                              });
                              _sendDriveFromJoystick(speed, angle);
                            },
                          ),
                        ),
                      ),
                      // Center: Compass + Motors
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CompassWidget(heading: _heading, size: 90),
                            const SizedBox(height: 12),
                            // Motor grid
                            SizedBox(
                              width: 160,
                              child: GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                                childAspectRatio: 2,
                                children: [
                                  _MotorCell(label: 'FL', value: '0.8'),
                                  _MotorCell(label: 'FR', value: '0.7'),
                                  _MotorCell(label: 'RL', value: '0.8'),
                                  _MotorCell(label: 'RR', value: '0.7'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right: Controls
                      Container(
                        width: 220,
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ServerPanel(
                                controller: _serverUrlCtrl,
                                client: _commandClient,
                                onConnect: () => _commandClient.connect(),
                                onDisconnect: _commandClient.disconnect,
                              ),
                              const SizedBox(height: 8),
                              _DirectionalPad(client: _commandClient),
                              const SizedBox(height: 8),
                              // Blade toggle
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.bgCard,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          PhosphorIconsBold.knife,
                                          size: 16,
                                          color: AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Blade',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              _bladeOn ? 'ON' : 'OFF',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: _bladeOn,
                                      onChanged: (v) {
                                        setState(() => _bladeOn = v);
                                        _commandClient.sendBladeCommand(v);
                                      },
                                      activeThumbColor: AppColors.brandBlue,
                                      inactiveTrackColor: AppColors.bgSurface,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _ControlButton(
                                icon: PhosphorIconsBold.play,
                                label: 'Auto Mode',
                                color: AppColors.brandBlue,
                                onPressed: () =>
                                    _commandClient.sendTaskResume(),
                              ),
                              const SizedBox(height: 8),
                              _ControlButton(
                                icon: PhosphorIconsBold.house,
                                label: 'Return to Dock',
                                color: AppColors.brandBlue,
                                onPressed: _commandClient.sendDock,
                              ),
                              const SizedBox(height: 8),
                              _ControlButton(
                                icon: PhosphorIconsBold.pause,
                                label: 'Pause',
                                color: AppColors.brandPurple,
                                onPressed: () => _commandClient.sendTaskPause(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // E-Stop at bottom center
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        width: 280,
                        child: EStopButton(
                          onActivated: _commandClient.sendEStop,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotorCell extends StatelessWidget {
  final String label;
  final String value;
  const _MotorCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: AppColors.brandPurple,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerPanel extends StatelessWidget {
  final TextEditingController controller;
  final RobotCommandClient client;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _ServerPanel({
    required this.controller,
    required this.client,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final connected = client.status == RobotCommandConnectionStatus.connected;
    final connecting = client.status == RobotCommandConnectionStatus.connecting;
    final ack = client.lastAck;
    final statusColor = switch (client.status) {
      RobotCommandConnectionStatus.connected => AppColors.statusGreen,
      RobotCommandConnectionStatus.connecting => AppColors.accentYellow,
      RobotCommandConnectionStatus.error => AppColors.accentRed,
      RobotCommandConnectionStatus.disconnected => AppColors.textMuted,
    };
    final statusText = switch (client.status) {
      RobotCommandConnectionStatus.connected => 'Connected',
      RobotCommandConnectionStatus.connecting => 'Connecting',
      RobotCommandConnectionStatus.error => 'Error',
      RobotCommandConnectionStatus.disconnected => 'Disconnected',
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                ack == null ? 'no ack' : 'received ✓',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ack == null
                      ? AppColors.textMuted
                      : AppColors.statusGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: TextField(
              controller: controller,
              onChanged: client.setServerUrl,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'ws://laptop-ip:8765/ws',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: connecting
                        ? null
                        : (connected ? onDisconnect : onConnect),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      backgroundColor: connected
                          ? AppColors.bgSurface
                          : AppColors.brandBlue,
                    ),
                    child: Text(
                      connected ? 'Disconnect' : 'Connect',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 34,
                child: OutlinedButton(
                  onPressed: connected ? client.sendPing : null,
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text('Ping', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
          if (client.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              client.errorMessage!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.accentRed),
            ),
          ],
        ],
      ),
    );
  }
}

class _DirectionalPad extends StatelessWidget {
  final RobotCommandClient client;

  const _DirectionalPad({required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text(
            'SERVER TEST COMMANDS',
            style: TextStyle(
              fontSize: 9,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _DirectionButton(
            label: 'Forward',
            icon: PhosphorIconsBold.arrowUp,
            onPressed: () => client.sendDirectionalCommand('forward'),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _DirectionButton(
                  label: 'Left',
                  icon: PhosphorIconsBold.arrowLeft,
                  onPressed: () => client.sendDirectionalCommand('left'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _DirectionButton(
                  label: 'Right',
                  icon: PhosphorIconsBold.arrowRight,
                  onPressed: () => client.sendDirectionalCommand('right'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _DirectionButton(
            label: 'Backward',
            icon: PhosphorIconsBold.arrowDown,
            onPressed: () => client.sendDirectionalCommand('backward'),
          ),
        ],
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _DirectionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 32,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 12),
        label: Text(label, style: const TextStyle(fontSize: 10)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
