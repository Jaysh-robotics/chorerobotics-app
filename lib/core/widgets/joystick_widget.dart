import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Joystick with displacement-proportional speed.
/// Output: normalized Offset (-1 to +1) where MAGNITUDE = speed factor.
/// - Center (0,0) = stopped
/// - Edge (1.0 magnitude) = max speed
/// - Intermediate = proportional speed (e.g., 0.5 = 50% speed)
///
/// The [deadzone] parameter (0.0-1.0) ignores small movements near center.
/// Default 0.1 = 10% of radius is treated as zero (prevents drift).
class JoystickWidget extends StatefulWidget {
  final double size;
  final ValueChanged<Offset>? onChanged;
  /// Called with speed magnitude (0.0 to 1.0) and angle in radians
  final void Function(double speed, double angle)? onSpeedChanged;
  final String? label;
  /// Dead zone radius as fraction of max (0.0-1.0). Default 0.1
  final double deadzone;

  const JoystickWidget({super.key, this.size = 160, this.onChanged, this.onSpeedChanged, this.label, this.deadzone = 0.1});

  @override
  State<JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<JoystickWidget> with SingleTickerProviderStateMixin {
  Offset _thumbOffset = Offset.zero;
  late AnimationController _springController;
  late Animation<Offset> _springAnimation;

  double get _maxRadius => widget.size / 2 - 30;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _springAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );
    _springController.addListener(() {
      setState(() => _thumbOffset = _springAnimation.value);
      widget.onChanged?.call(_normalize(_thumbOffset));
      widget.onSpeedChanged?.call(_speedFromOffset(_thumbOffset), _angleFromOffset(_thumbOffset));
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  Offset _normalize(Offset offset) {
    final raw = Offset(
      (offset.dx / _maxRadius).clamp(-1.0, 1.0),
      (offset.dy / _maxRadius).clamp(-1.0, 1.0),
    );
    // Apply deadzone — if magnitude < deadzone, treat as zero
    if (raw.distance < widget.deadzone) return Offset.zero;
    return raw;
  }

  /// Speed magnitude (0.0 to 1.0) based on distance from center
  double _speedFromOffset(Offset offset) {
    final normalized = _normalize(offset);
    return normalized.distance.clamp(0.0, 1.0);
  }

  /// Angle in radians from center
  double _angleFromOffset(Offset offset) {
    final normalized = _normalize(offset);
    if (normalized == Offset.zero) return 0;
    return normalized.direction; // radians, -pi to pi
  }

  Offset _clampToCircle(Offset offset) {
    final distance = offset.distance;
    if (distance <= _maxRadius) return offset;
    return offset / distance * _maxRadius;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _thumbOffset = _clampToCircle(_thumbOffset + details.delta);
            });
            final norm = _normalize(_thumbOffset);
            widget.onChanged?.call(norm);
            widget.onSpeedChanged?.call(_speedFromOffset(_thumbOffset), _angleFromOffset(_thumbOffset));
          },
          onPanEnd: (_) {
            _springAnimation = Tween<Offset>(begin: _thumbOffset, end: Offset.zero).animate(
              CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
            );
            _springController.forward(from: 0);
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Crosshair
                Container(width: 1, height: widget.size, color: AppColors.border),
                Container(width: widget.size, height: 1, color: AppColors.border),
                // Thumb
                Transform.translate(
                  offset: _thumbOffset,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.brandBlue, AppColors.brandPurple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandBlue.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.label!,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
        ],
      ],
    );
  }
}
