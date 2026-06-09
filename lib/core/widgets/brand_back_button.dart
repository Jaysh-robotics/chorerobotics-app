import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../theme/app_colors.dart';

/// Square back chip used in screen headers. Pops the GoRouter stack; falls back
/// to /dashboard when there is nothing to pop (e.g. opened via deep link).
class BrandBackButton extends StatelessWidget {
  final String fallbackRoute;
  final VoidCallback? onTap;

  const BrandBackButton({
    super.key,
    this.fallbackRoute = '/dashboard',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallbackRoute);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          color: AppColors.bgCard,
        ),
        child: const Icon(
          PhosphorIconsBold.caretLeft,
          size: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
