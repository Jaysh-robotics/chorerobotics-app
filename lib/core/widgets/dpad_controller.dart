import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

enum DpadDirection { up, down, left, right, upLeft, upRight, downLeft, downRight, none }

class DpadController extends StatelessWidget {
  final ValueChanged<DpadDirection>? onDirectionChanged;
  final VoidCallback? onDirectionReleased;
  final double size;
  final String? label;

  const DpadController({
    super.key,
    this.onDirectionChanged,
    this.onDirectionReleased,
    this.size = 180,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final btnSize = size * 0.30;
    final centerSize = size * 0.32;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1.5),
                  color: AppColors.bgSurface,
                ),
              ),
              // Up
              Positioned(
                top: 4,
                child: _DpadButton(
                  icon: Icons.keyboard_arrow_up,
                  width: btnSize,
                  height: btnSize,
                  onPressed: () => _fire(DpadDirection.up),
                  onReleased: _release,
                ),
              ),
              // Down
              Positioned(
                bottom: 4,
                child: _DpadButton(
                  icon: Icons.keyboard_arrow_down,
                  width: btnSize,
                  height: btnSize,
                  onPressed: () => _fire(DpadDirection.down),
                  onReleased: _release,
                ),
              ),
              // Left
              Positioned(
                left: 4,
                child: _DpadButton(
                  icon: Icons.keyboard_arrow_left,
                  width: btnSize,
                  height: btnSize,
                  onPressed: () => _fire(DpadDirection.left),
                  onReleased: _release,
                ),
              ),
              // Right
              Positioned(
                right: 4,
                child: _DpadButton(
                  icon: Icons.keyboard_arrow_right,
                  width: btnSize,
                  height: btnSize,
                  onPressed: () => _fire(DpadDirection.right),
                  onReleased: _release,
                ),
              ),
              // Center circle
              Container(
                width: centerSize,
                height: centerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgCard,
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
        ],
      ],
    );
  }

  void _fire(DpadDirection dir) {
    HapticFeedback.lightImpact();
    onDirectionChanged?.call(dir);
  }

  void _release() {
    onDirectionReleased?.call();
  }
}

class _DpadButton extends StatefulWidget {
  final IconData icon;
  final double width;
  final double height;
  final VoidCallback onPressed;
  final VoidCallback onReleased;

  const _DpadButton({
    required this.icon,
    required this.width,
    required this.height,
    required this.onPressed,
    required this.onReleased,
  });

  @override
  State<_DpadButton> createState() => _DpadButtonState();
}

class _DpadButtonState extends State<_DpadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        widget.onPressed();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onReleased();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        widget.onReleased();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pressed ? AppColors.brandBlue.withValues(alpha: 0.2) : Colors.transparent,
        ),
        child: Icon(
          widget.icon,
          size: widget.width * 0.55,
          color: _pressed ? AppColors.brandBlue : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Small D-pad for secondary controls (chute angle, module angle)
class MiniDpad extends StatelessWidget {
  final String label;
  final ValueChanged<DpadDirection>? onChanged;
  final bool verticalOnly;

  const MiniDpad({super.key, required this.label, this.onChanged, this.verticalOnly = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MiniBtn(icon: Icons.keyboard_arrow_up, onTap: () => onChanged?.call(DpadDirection.up)),
        if (!verticalOnly)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniBtn(icon: Icons.keyboard_arrow_left, onTap: () => onChanged?.call(DpadDirection.left)),
              const SizedBox(width: 24),
              _MiniBtn(icon: Icons.keyboard_arrow_right, onTap: () => onChanged?.call(DpadDirection.right)),
            ],
          ),
        _MiniBtn(icon: Icons.keyboard_arrow_down, onTap: () => onChanged?.call(DpadDirection.down)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
      ],
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MiniBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bgCard,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}
