import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/dpad_controller.dart';
import '../../../core/widgets/compass_widget.dart';
import '../../../core/widgets/brand_badge.dart';
import '../../../core/widgets/estop_button.dart';

class DpadControlScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const DpadControlScreen({super.key, this.onBack});

  @override
  State<DpadControlScreen> createState() => _DpadControlScreenState();
}

class _DpadControlScreenState extends State<DpadControlScreen> {
  bool _bladeOn = false;
  double _speed = 0.0;
  double _heading = 0;
  int _augerSpeed = 0;
  DpadDirection _currentDir = DpadDirection.none;

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

  void _onDirection(DpadDirection dir) {
    setState(() {
      _currentDir = dir;
      switch (dir) {
        case DpadDirection.up:
          _speed = 1.0;
          break;
        case DpadDirection.down:
          _speed = -0.5; // reverse is slower
          break;
        case DpadDirection.left:
          _heading = (_heading - 15) % 360;
          break;
        case DpadDirection.right:
          _heading = (_heading + 15) % 360;
          break;
        case DpadDirection.upLeft:
          _speed = 0.8;
          _heading = (_heading - 10) % 360;
          break;
        case DpadDirection.upRight:
          _speed = 0.8;
          _heading = (_heading + 10) % 360;
          break;
        default:
          break;
      }
    });
  }

  void _onRelease() {
    setState(() {
      _speed = 0.0;
      _currentDir = DpadDirection.none;
    });
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.bgSecondary,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
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
                  const Text('Local', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  const BrandBadge(label: 'D-PAD', variant: BadgeVariant.purple),
                  const Spacer(),
                  // Speed + Heading
                  Column(
                    children: [
                      const Text('SPEED', style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_speed.abs().toStringAsFixed(1), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'monospace', letterSpacing: -1)),
                          const Text(' m/s', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 20), color: AppColors.border),
                  Column(
                    children: [
                      const Text('HEADING', style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_heading.round().toString().padLeft(3, '0'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'monospace', letterSpacing: -1)),
                          const Text('\u00B0', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(PhosphorIconsBold.batteryFull, size: 14, color: AppColors.brandBlue),
                  const SizedBox(width: 4),
                  const Text('78%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandBlue)),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Left side controls
                      Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Clear Error
                            _SideButton(icon: PhosphorIconsBold.arrowCounterClockwise, label: 'Clear\nError', color: AppColors.accentYellow),
                            const SizedBox(height: 8),
                            // Front Light
                            _SideButton(icon: PhosphorIconsBold.lightbulb, label: 'Front\nLight', color: AppColors.brandBlue),
                            const SizedBox(height: 8),
                            // Blade Speed
                            _SpeedSelector(
                              label: 'Blade\nSpeed',
                              value: _augerSpeed,
                              max: 3,
                              onChanged: (v) => setState(() => _augerSpeed = v),
                            ),
                          ],
                        ),
                      ),
                      // Center: top actions + D-pad + compass
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            // Stop + Recharge row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _ActionBtn(icon: PhosphorIconsBold.pause, label: 'Stop', color: AppColors.accentRed, bgColor: AppColors.accentRed.withValues(alpha: 0.12)),
                                const SizedBox(width: 12),
                                _ActionBtn(icon: PhosphorIconsBold.batteryFull, label: 'Recharge', color: AppColors.statusGreen, bgColor: AppColors.statusGreen.withValues(alpha: 0.12)),
                              ],
                            ),
                            const Spacer(),
                            // D-pad + Compass
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                DpadController(
                                  size: 160,
                                  label: 'DRIVE',
                                  onDirectionChanged: _onDirection,
                                  onDirectionReleased: _onRelease,
                                ),
                                const SizedBox(width: 24),
                                CompassWidget(heading: _heading, size: 80),
                              ],
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      // Right side controls
                      Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.border))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Blade toggle
                            _SideToggle(
                              icon: PhosphorIconsBold.knife,
                              label: 'Blade',
                              isOn: _bladeOn,
                              onToggle: () => setState(() => _bladeOn = !_bladeOn),
                            ),
                            const SizedBox(height: 12),
                            // Chute / Module angle
                            MiniDpad(
                              label: 'Chute\n(Angle)',
                              verticalOnly: true,
                              onChanged: (_) {},
                            ),
                            const SizedBox(height: 12),
                            MiniDpad(
                              label: 'Module\n(Angle)',
                              verticalOnly: true,
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Direction indicator
                  if (_currentDir != DpadDirection.none)
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brandBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _currentDir.name.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandBlue, letterSpacing: 1),
                          ),
                        ),
                      ),
                    ),
                  // E-Stop
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(child: SizedBox(width: 260, child: EStopButton(onActivated: () {}))),
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

class _SideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SideButton({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _SideToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isOn;
  final VoidCallback onToggle;
  const _SideToggle({required this.icon, required this.label, required this.isOn, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isOn ? AppColors.brandBlue.withValues(alpha: 0.15) : AppColors.bgCard,
          border: Border.all(color: isOn ? AppColors.brandBlue.withValues(alpha: 0.3) : AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isOn ? AppColors.brandBlue : AppColors.textMuted),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 9, color: isOn ? AppColors.brandBlue : AppColors.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(isOn ? 'ON' : 'OFF', style: TextStyle(fontSize: 8, color: isOn ? AppColors.brandBlue : AppColors.textMuted, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: bgColor,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _SpeedSelector extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  const _SpeedSelector({required this.label, required this.value, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(max + 1, (i) {
          final level = max - i;
          final isActive = level <= value;
          return GestureDetector(
            onTap: () => onChanged(level),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isActive ? AppColors.brandBlue.withValues(alpha: 0.2) : AppColors.bgCard,
                border: Border.all(color: isActive ? AppColors.brandBlue.withValues(alpha: 0.3) : AppColors.border),
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.brandBlue : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600, height: 1.2)),
      ],
    );
  }
}
