import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class JoystickWidget extends StatefulWidget {
  final double size;
  final ValueChanged<Offset>? onChanged;
  final String? label;

  const JoystickWidget({super.key, this.size = 160, this.onChanged, this.label});

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
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  Offset _normalize(Offset offset) {
    return Offset(
      (offset.dx / _maxRadius).clamp(-1.0, 1.0),
      (offset.dy / _maxRadius).clamp(-1.0, 1.0),
    );
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
            widget.onChanged?.call(_normalize(_thumbOffset));
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
