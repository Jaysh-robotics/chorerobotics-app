import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SignalBars extends StatelessWidget {
  final int strength; // 0-4
  final double height;

  const SignalBars({super.key, required this.strength, this.height = 20});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        final isActive = index < strength;
        final barHeight = height * (0.4 + 0.2 * index);
        return Container(
          width: 3,
          height: barHeight,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isActive
                ? (index < 2 ? AppColors.brandBlue : AppColors.brandPurple)
                : AppColors.border,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
