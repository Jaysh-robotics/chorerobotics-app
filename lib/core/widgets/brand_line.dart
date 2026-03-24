import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BrandLineWidget extends StatelessWidget {
  const BrandLineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.4,
      child: Container(
        height: 2,
        decoration: const BoxDecoration(
          gradient: AppColors.brandGradientHorizontal,
        ),
      ),
    );
  }
}
