import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class EStopButton extends StatefulWidget {
  final VoidCallback? onActivated;

  const EStopButton({super.key, this.onActivated});

  @override
  State<EStopButton> createState() => _EStopButtonState();
}

class _EStopButtonState extends State<EStopButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.heavyImpact();
        widget.onActivated?.call();
      },
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.estopRed,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.estopYellow, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.estopRed.withValues(alpha: 0.5),
              blurRadius: 24,
            ),
            BoxShadow(
              color: AppColors.estopYellow.withValues(alpha: 0.3),
              blurRadius: 0,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Color(0x66000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final opacity = 0.5 + 0.5 * (1 - _pulseController.value).abs();
                final scale = 1.0 + 0.3 * _pulseController.value;
                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            const Text(
              'EMERGENCY STOP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
