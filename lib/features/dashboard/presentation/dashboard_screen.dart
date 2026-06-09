import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/connection_bar.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/brand_badge.dart';
import '../../../core/widgets/metric_row.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const ConnectionBar(),
          // App Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Image.asset(
                  'assets/logo/chore-robotics-mark.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dashboard', style: Theme.of(context).textTheme.headlineLarge),
                      const Text('ChoreBot Alpha', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [AppColors.brandBlue, AppColors.brandPurple]),
                        ),
                        child: const Center(
                          child: Text('JS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => context.push('/settings'),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                          color: AppColors.bgCard,
                        ),
                        child: const Icon(PhosphorIconsBold.gear, size: 16, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
              child: Column(
                children: [
                  // Status Card
                  BrandCard(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.bgCard, AppColors.brandBlue.withValues(alpha: 0.05)],
                    ),
                    borderColor: AppColors.brandBlue.withValues(alpha: 0.15),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ROBOT STATUS', style: Theme.of(context).textTheme.labelSmall),
                            const BrandBadge(label: 'Idle', variant: BadgeVariant.green, showDot: true),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.bgSurface),
                              child: const Icon(PhosphorIconsBold.robot, size: 28, color: AppColors.textMuted),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ready to work', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                                  SizedBox(height: 2),
                                  Text('Mower Blade attached', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Battery', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            Text('78% — ~2h 15m', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandBlue)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            height: 6,
                            decoration: const BoxDecoration(color: AppColors.bgSurface),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: 0.78,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: AppColors.bluePurpleGradient,
                                  borderRadius: BorderRadius.all(Radius.circular(100)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.03),
                  const SizedBox(height: 10),
                  // Quick Actions — navigate to task screens
                  Row(
                    children: [
                      _QuickAction(
                        icon: PhosphorIconsBold.plant,
                        label: 'Mow',
                        gradient: LinearGradient(
                          colors: [AppColors.brandBlue.withValues(alpha: 0.15), AppColors.brandPurple.withValues(alpha: 0.15)],
                        ),
                        iconColor: AppColors.brandBlue,
                        onTap: () => context.push('/mowing'),
                      ),
                      const SizedBox(width: 8),
                      _QuickAction(
                        icon: PhosphorIconsBold.snowflake,
                        label: 'Plow',
                        gradient: LinearGradient(
                          colors: [AppColors.brandPurple.withValues(alpha: 0.12), AppColors.brandPurple.withValues(alpha: 0.08)],
                        ),
                        iconColor: AppColors.brandPurple,
                        onTap: () => context.push('/snow'),
                      ),
                      const SizedBox(width: 8),
                      _QuickAction(
                        icon: PhosphorIconsBold.leaf,
                        label: 'Collect',
                        color: AppColors.magentaDim,
                        iconColor: AppColors.brandMagenta,
                        onTap: () => context.push('/leaf'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                  const SizedBox(height: 10),
                  // Live Metrics
                  BrandCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('LIVE METRICS', style: Theme.of(context).textTheme.labelSmall),
                            const BrandBadge(label: 'LIVE', variant: BadgeVariant.magenta, showDot: true),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const MetricRow(label: 'Battery Cycles', value: '142 / 500'),
                        MetricRow(label: 'Signal', value: 'Strong', valueColor: AppColors.brandBlue),
                        const MetricRow(label: 'Blade', value: 'Standby', valueColor: AppColors.textMuted),
                        const MetricRow(label: 'Speed', value: '0.0 m/s'),
                        const MetricRow(label: 'Temperature', value: '32°C', isLast: true),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                  const SizedBox(height: 10),
                  // Recent Activity
                  BrandCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('RECENT ACTIVITY', style: Theme.of(context).textTheme.labelSmall),
                            Text('View All', style: TextStyle(fontSize: 12, color: AppColors.brandMagenta, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _LogEntry(color: AppColors.brandBlue, text: 'Mowed Front Yard — Zone 1 complete', time: '2 hours ago'),
                        _LogEntry(color: AppColors.brandBlue, text: 'Returned to dock — battery at 22%', time: '2 hours ago'),
                        _LogEntry(color: AppColors.accentYellow, text: 'Connection unstable during mow', time: '3 hours ago', isLast: true),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Gradient? gradient;
  final Color iconColor;
  final VoidCallback? onTap;

  const _QuickAction({required this.icon, required this.label, this.color, this.gradient, required this.iconColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          color: AppColors.bgCard,
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: gradient == null ? color : null,
                gradient: gradient,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ],
        ),
        ),
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  final Color color;
  final String text;
  final String time;
  final bool isLast;

  const _LogEntry({required this.color, required this.text, required this.time, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
