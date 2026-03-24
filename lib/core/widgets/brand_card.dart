import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BrandCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool selected;

  const BrandCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: gradient == null ? AppColors.bgCard : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.brandBlue
                : borderColor ?? AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
