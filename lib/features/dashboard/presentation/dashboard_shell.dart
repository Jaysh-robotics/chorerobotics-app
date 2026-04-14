import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/estop_button.dart';
import '../../active_task/presentation/active_task_overlay.dart';
import 'dashboard_screen.dart';
import '../../control/presentation/control_screen.dart';
import '../../control/presentation/dpad_control_screen.dart';
import '../../map/presentation/map_screen.dart';
import '../../battery/presentation/battery_screen.dart';
import '../../diagnostics/presentation/diagnostics_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;
  bool _useDpad = false; // toggle between joystick and D-pad

  void _goHome() => setState(() => _currentIndex = 0);

  Widget _buildScreen() {
    switch (_currentIndex) {
      case 0: return const DashboardScreen();
      case 1: return _useDpad
          ? DpadControlScreen(onBack: _goHome)
          : ControlScreen(onBack: _goHome);
      case 2: return MapScreen(onBack: _goHome);
      case 3: return const BatteryScreen();
      case 4: return const DiagnosticsScreen();
      default: return const DashboardScreen();
    }
  }

  // Landscape screens hide bottom nav and E-Stop (they have their own)
  bool get _isLandscape => _currentIndex == 1 || _currentIndex == 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          _buildScreen(),
          // Active task overlay (above content, below E-Stop)
          if (!_isLandscape) const Positioned(
            bottom: 145,
            left: 0,
            right: 0,
            child: ActiveTaskOverlay(),
          ),
          // E-Stop overlay (only for portrait screens)
          if (!_isLandscape) Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: EStopButton(
              onActivated: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('E-STOP ACTIVATED', style: TextStyle(fontWeight: FontWeight.w800)),
                    backgroundColor: AppColors.estopRed,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isLandscape ? null : Container(
        decoration: const BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: PhosphorIconsBold.squaresFour, label: 'Home', isActive: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
                _NavItem(
                  icon: _useDpad ? PhosphorIconsBold.gameController : PhosphorIconsBold.joystick,
                  label: _useDpad ? 'D-Pad' : 'Joystick',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                  onLongPress: () => setState(() {
                    _useDpad = !_useDpad;
                    if (_currentIndex == 1) {} // refresh if already on control
                  }),
                ),
                _NavItem(icon: PhosphorIconsBold.mapTrifold, label: 'Map', isActive: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
                _NavItem(icon: PhosphorIconsBold.batteryFull, label: 'Battery', isActive: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
                _NavItem(icon: PhosphorIconsBold.list, label: 'More', isActive: _currentIndex == 4, onTap: () => setState(() => _currentIndex = 4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: isActive ? AppColors.brandBlue : AppColors.textMuted),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.brandBlue : AppColors.textMuted,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 16,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.brandBlue,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }
}

// Placeholder removed — all screens now implemented
