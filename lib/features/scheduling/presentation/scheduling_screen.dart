import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/connection_bar.dart';
import '../../../core/widgets/brand_card.dart';

class SchedulingScreen extends StatelessWidget {
  const SchedulingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            const ConnectionBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Schedules', style: Theme.of(context).textTheme.headlineLarge),
                      const Text('Automated tasks', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.brandBlue,
                    ),
                    child: const Icon(PhosphorIconsBold.plus, size: 18, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  children: [
                    _ScheduleCard(
                      title: 'Sunday Front Yard',
                      icon: PhosphorIconsBold.plant,
                      taskType: 'Mow',
                      time: '8:00 AM',
                      days: 'Sunday',
                      zone: 'Zone 1 — Front Yard',
                      pattern: 'Straight stripes',
                      enabled: true,
                      color: AppColors.brandBlue,
                    ).animate().fadeIn(duration: 200.ms),
                    const SizedBox(height: 8),
                    _ScheduleCard(
                      title: 'Wed/Sat Driveway',
                      icon: PhosphorIconsBold.snowflake,
                      taskType: 'Plow',
                      time: '6:30 AM',
                      days: 'Wed, Sat',
                      zone: 'Driveway',
                      pattern: 'Auto-trigger on snow',
                      enabled: true,
                      color: AppColors.brandPurple,
                    ).animate().fadeIn(delay: 100.ms, duration: 200.ms),
                    const SizedBox(height: 8),
                    _ScheduleCard(
                      title: 'Friday Leaf Cleanup',
                      icon: PhosphorIconsBold.leaf,
                      taskType: 'Collect',
                      time: '3:00 PM',
                      days: 'Friday',
                      zone: 'Under Oak',
                      pattern: 'Bag mode',
                      enabled: false,
                      color: AppColors.brandMagenta,
                    ).animate().fadeIn(delay: 200.ms, duration: 200.ms),
                    const SizedBox(height: 24),
                    // Empty state hint
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          Icon(PhosphorIconsBold.calendarPlus, size: 32, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text('Tap + to add a new schedule', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          const Text('Set your robot to work automatically', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
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

class _ScheduleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String taskType;
  final String time;
  final String days;
  final String zone;
  final String pattern;
  final bool enabled;
  final Color color;

  const _ScheduleCard({
    required this.title,
    required this.icon,
    required this.taskType,
    required this.time,
    required this.days,
    required this.zone,
    required this.pattern,
    required this.enabled,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      borderColor: enabled ? color.withValues(alpha: 0.2) : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: enabled ? AppColors.textPrimary : AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(taskType, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                        Text(' · $time · $days', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: (_) {},
                activeThumbColor: color,
                inactiveTrackColor: AppColors.bgSurface,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 48),
              Text('$zone · $pattern', style: TextStyle(fontSize: 11, color: enabled ? AppColors.textMuted : AppColors.textMuted.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }
}
