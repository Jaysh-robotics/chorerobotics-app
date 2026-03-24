import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MetricRow extends StatelessWidget {
  final String label;
  final String? value;
  final Color? valueColor;
  final Widget? trailing;
  final bool isLast;

  const MetricRow({
    super.key,
    required this.label,
    this.value,
    this.valueColor,
    this.trailing,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          trailing ??
              Text(
                value ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                  fontFamily: 'monospace',
                ),
              ),
        ],
      ),
    );
  }
}
