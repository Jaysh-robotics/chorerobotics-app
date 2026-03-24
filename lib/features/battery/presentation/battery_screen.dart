import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/connection_bar.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/brand_badge.dart';
import '../../../core/widgets/metric_row.dart';

class BatteryScreen extends StatelessWidget {
  const BatteryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const ConnectionBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Battery', style: Theme.of(context).textTheme.headlineLarge),
                const Text('Health & Status', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
              child: Column(
                children: [
                  // Big Battery Display
                  BrandCard(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.bgCard, AppColors.brandBlue.withValues(alpha: 0.05)],
                    ),
                    borderColor: AppColors.brandBlue.withValues(alpha: 0.12),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Battery visualization
                        SizedBox(
                          width: 100,
                          height: 160,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Shell
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.3), width: 3),
                                ),
                                child: Stack(
                                  children: [
                                    // Fill
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: FractionallySizedBox(
                                        heightFactor: 1,
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            height: 160 * 0.78,
                                            decoration: BoxDecoration(
                                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
                                              gradient: const LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [AppColors.brandBlue, AppColors.brandPurple],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Percentage text
                                    const Center(
                                      child: Text(
                                        '78%',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          shadows: [Shadow(color: Color(0x80000000), blurRadius: 8)],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Cap
                              Positioned(
                                top: -8,
                                left: 30,
                                child: Container(
                                  width: 40,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.brandBlue.withValues(alpha: 0.3),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().scale(begin: const Offset(0.9, 0.9), duration: 500.ms, curve: Curves.easeOut),
                        const SizedBox(height: 20),
                        const Text('Estimated Runtime', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        const Text('~2h 15m mowing', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const BrandBadge(label: 'Discharging', variant: BadgeVariant.blue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Health Card
                  BrandCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('HEALTH', style: Theme.of(context).textTheme.labelSmall),
                            const BrandBadge(label: 'Good', variant: BadgeVariant.blue),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const MetricRow(label: 'Cycle Count', value: '142 / 500'),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              height: 4,
                              color: AppColors.bgSurface,
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: 0.28,
                                child: Container(color: AppColors.brandBlue),
                              ),
                            ),
                          ),
                        ),
                        MetricRow(label: 'Battery Health', value: '94%', valueColor: AppColors.brandPurple),
                        const MetricRow(label: 'Temperature', value: '32°C'),
                        const MetricRow(label: 'Voltage', value: '25.2V'),
                        const MetricRow(label: 'Current Draw', value: '3.2A', isLast: true),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 10),
                  // History Chart placeholder
                  BrandCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('7-DAY HISTORY', style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 16),
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.bgSurface,
                          ),
                          child: const Center(
                            child: Text('Chart — fl_chart integration', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
