import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../theme/app_colors.dart';
import 'brand_line.dart';

class ConnectionBar extends StatelessWidget {
  final String mode;
  final int batteryPercent;
  final bool showBrandLine;

  const ConnectionBar({
    super.key,
    this.mode = 'Local',
    this.batteryPercent = 78,
    this.showBrandLine = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBrandLine) const BrandLineWidget(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: const BoxDecoration(
            color: AppColors.bgSecondary,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.statusGreen,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    mode,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    PhosphorIconsBold.batteryFull,
                    size: 16,
                    color: AppColors.brandBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$batteryPercent%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
