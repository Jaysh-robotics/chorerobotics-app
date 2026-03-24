import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BadgeVariant { blue, purple, magenta, green, yellow, red, orange }

class BrandBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final bool showDot;

  const BrandBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.blue,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Text('● ', style: TextStyle(color: fg, fontSize: 8)),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) get _colors => switch (variant) {
    BadgeVariant.blue => (AppColors.blueDim, AppColors.brandBlue),
    BadgeVariant.purple => (AppColors.purpleDim, AppColors.brandPurple),
    BadgeVariant.magenta => (AppColors.magentaDim, AppColors.brandMagenta),
    BadgeVariant.green => (AppColors.greenDim, AppColors.statusGreen),
    BadgeVariant.yellow => (AppColors.yellowDim, AppColors.accentYellow),
    BadgeVariant.red => (AppColors.redDim, AppColors.accentRed),
    BadgeVariant.orange => (AppColors.orangeDim, AppColors.accentOrange),
  };
}
