import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep; // 0-indexed

  const StepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Image.asset(
              'assets/logo/chore-robotics-mark.png',
              height: 26,
              fit: BoxFit.contain,
            ),
          ),
          _buildDots(),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            final lineIndex = index ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: lineIndex < currentStep
                    ? AppColors.brandPurple
                    : AppColors.border,
              ),
            );
          }
          final stepIndex = index ~/ 2;
          final isDone = stepIndex < currentStep;
          final isActive = stepIndex == currentStep;

          return Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? AppColors.brandPurple
                  : isActive
                      ? AppColors.brandBlue
                      : AppColors.bgSurface,
              border: Border.all(
                color: isDone
                    ? AppColors.brandPurple
                    : isActive
                        ? AppColors.brandBlue
                        : AppColors.border,
                width: 2,
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : AppColors.textMuted,
                      ),
                    ),
            ),
          );
        }),
    );
  }
}
