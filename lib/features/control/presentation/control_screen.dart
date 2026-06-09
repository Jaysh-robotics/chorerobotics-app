import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
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
  bool _bladeOn = false;
  double _speed = 0.8;
  double _heading = 45;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

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
                          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                          widget.onBack?.call();
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_back, size: 20, color: AppColors.textSecondary),
                        ),
                      ),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.statusGreen)),
                      const SizedBox(width: 6),
                      const Text('Local', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      const BrandBadge(label: 'MANUAL', variant: BadgeVariant.purple),
                    ],
                  ),
                  const Spacer(),
                  // Center: speed + heading
                  Row(
                    children: [
                      Column(
                        children: [
                          const Text('SPEED', style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_speed.toStringAsFixed(1), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'monospace', letterSpacing: -1)),
                              const Text(' m/s', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                      Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 24), color: AppColors.border),
                      Column(
                        children: [
                          const Text('HEADING', style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_heading.round().toString().padLeft(3, '0'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'monospace', letterSpacing: -1)),
                              const Text('°', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
                      const Icon(PhosphorIconsBold.batteryFull, size: 14, color: AppColors.brandBlue),
                      const SizedBox(width: 4),
                      const Text('78%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandBlue)),
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
                        decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
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
                                  // Convert joystick angle to heading
                                  _heading = ((_heading + angle * 2) % 360 + 360) % 360;
                                }
                              });
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
                        decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.border))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Blade toggle
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(PhosphorIconsBold.knife, size: 16, color: AppColors.textMuted),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Blade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                          Text(_bladeOn ? 'ON' : 'OFF', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _bladeOn,
                                    onChanged: (v) => setState(() => _bladeOn = v),
                                    activeThumbColor: AppColors.brandBlue,
                                    inactiveTrackColor: AppColors.bgSurface,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            _ControlButton(icon: PhosphorIconsBold.play, label: 'Auto Mode', color: AppColors.brandBlue),
                            const SizedBox(height: 8),
                            _ControlButton(icon: PhosphorIconsBold.house, label: 'Return to Dock', color: AppColors.brandBlue),
                            const SizedBox(height: 8),
                            _ControlButton(icon: PhosphorIconsBold.pause, label: 'Pause', color: AppColors.brandPurple),
                          ],
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
                        child: EStopButton(onActivated: () {}),
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
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: AppColors.brandPurple)),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ControlButton({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: () {},
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
