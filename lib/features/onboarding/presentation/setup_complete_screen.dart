import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/step_indicator.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/brand_badge.dart';

class SetupCompleteScreen extends StatelessWidget {
  const SetupCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            const StepIndicator(totalSteps: 4, currentStep: 4), // all done
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('All Set', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 2),
                    Text('Your robot is ready to go', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 24),

                    // Brand mark celebration with success check
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.accentOrange.withValues(alpha: 0.18),
                                  AppColors.accentOrange.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/logo/chore-robotics-mark.png',
                            width: 88,
                            height: 88,
                            fit: BoxFit.contain,
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.statusGreen,
                                border: Border.all(color: AppColors.bgPrimary, width: 2),
                              ),
                              child: const Icon(Icons.check, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .scale(begin: const Offset(0.6, 0.6), duration: 600.ms, curve: Curves.elasticOut)
                        .fadeIn(duration: 300.ms),

                    const SizedBox(height: 24),

                    // Robot Summary Card
                    BrandCard(
                      borderColor: AppColors.brandBlue.withValues(alpha: 0.12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.bgCard, AppColors.brandBlue.withValues(alpha: 0.04)],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: AppColors.bgSurface,
                                ),
                                child: const Icon(Icons.smart_toy_outlined, color: AppColors.textMuted, size: 28),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ChoreBot Alpha', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                                    SizedBox(height: 2),
                                    Text('Paired and connected', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _MetricRow('Connection', child: const BrandBadge(label: 'Local Wi-Fi', variant: BadgeVariant.blue)),
                          _MetricRow('Network', value: 'HomeWiFi-5G'),
                          _MetricRow('Battery', value: '100%', valueColor: AppColors.brandBlue),
                          _MetricRow('Attachment', value: 'Mower Blade', isLast: true),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 8),

                    // What's Next
                    BrandCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WHAT\'S NEXT', style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 12),
                          _NextStep(
                            number: '1',
                            color: AppColors.brandBlue,
                            bgColor: AppColors.blueDim,
                            title: 'Set up your yard',
                            subtitle: 'Draw boundaries and zones on the map',
                          ),
                          _NextStep(
                            number: '2',
                            color: AppColors.brandPurple,
                            bgColor: AppColors.purpleDim,
                            title: 'Choose a mowing pattern',
                            subtitle: 'Pick stripes, diagonal, or let the robot decide',
                          ),
                          _NextStep(
                            number: '3',
                            color: AppColors.brandMagenta,
                            bgColor: AppColors.magentaDim,
                            title: 'Start your first job',
                            subtitle: 'Tap Start on the dashboard and watch it go',
                            isLast: true,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('Go to Dashboard'),
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String? value;
  final Color? valueColor;
  final Widget? child;
  final bool isLast;

  const _MetricRow(this.label, {this.value, this.valueColor, this.child, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          child ??
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

class _NextStep extends StatelessWidget {
  final String number;
  final Color color;
  final Color bgColor;
  final String title;
  final String subtitle;
  final bool isLast;

  const _NextStep({
    required this.number,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: bgColor,
            ),
            child: Center(
              child: Text(number, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
