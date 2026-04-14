import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/connection_bar.dart';
import '../../active_task/bloc/active_task_bloc.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/brand_badge.dart';

class MowingScreen extends StatefulWidget {
  const MowingScreen({super.key});

  @override
  State<MowingScreen> createState() => _MowingScreenState();
}

class _MowingScreenState extends State<MowingScreen> {
  int _selectedPattern = 0;
  double _angle = 45;
  double _overlap = 10;

  void _simulateProgress(BuildContext ctx) {
    // Demo: simulate progress ticking up, then get "stuck" at 65%
    final bloc = ctx.read<ActiveTaskBloc>();
    Future.delayed(const Duration(seconds: 2), () {
      if (!ctx.mounted) return;
      bloc.add(const TaskProgressUpdated(completedAreaSqM: 28, progressPercent: 20, batteryUsed: 8, elapsedSeconds: 120));
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (!ctx.mounted) return;
      bloc.add(const TaskProgressUpdated(completedAreaSqM: 56, progressPercent: 40, batteryUsed: 16, elapsedSeconds: 240));
    });
    Future.delayed(const Duration(seconds: 6), () {
      if (!ctx.mounted) return;
      bloc.add(const TaskProgressUpdated(completedAreaSqM: 92, progressPercent: 65, batteryUsed: 28, elapsedSeconds: 420));
    });
    Future.delayed(const Duration(seconds: 8), () {
      if (!ctx.mounted) return;
      bloc.add(const TaskFailed('stuck'));
    });
  }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start Mowing', style: Theme.of(context).textTheme.headlineLarge),
                  const Text('Mow Zone 1 — Front Yard', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Zone summary
                    BrandCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: AppColors.bgSurface),
                                child: const Icon(PhosphorIconsBold.robot, size: 20, color: AppColors.textMuted),
                              ),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Front Yard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  Text('142 m² — 1 no-go zone', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ],
                          ),
                          const BrandBadge(label: 'Ready', variant: BadgeVariant.blue),
                        ],
                      ),
                    ).animate().fadeIn(duration: 200.ms),
                    const SizedBox(height: 12),
                    // Pattern Selection
                    Text('STRIPE PATTERN', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.2,
                      children: [
                        _PatternCard(name: 'Straight', isSelected: _selectedPattern == 0, onTap: () => setState(() => _selectedPattern = 0), icon: PhosphorIconsBold.arrowsVertical),
                        _PatternCard(name: 'Diagonal', isSelected: _selectedPattern == 1, onTap: () => setState(() => _selectedPattern = 1), icon: PhosphorIconsBold.arrowUpRight),
                        _PatternCard(name: 'Checker', isSelected: _selectedPattern == 2, onTap: () => setState(() => _selectedPattern = 2), icon: PhosphorIconsBold.gridFour, subtitle: '2x time'),
                        _PatternCard(name: 'Spiral', isSelected: _selectedPattern == 3, onTap: () => setState(() => _selectedPattern = 3), icon: PhosphorIconsBold.spiral),
                      ],
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 12),
                    // Angle Slider
                    BrandCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Stripe Angle', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              Text('${_angle.round()}°', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                            ],
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppColors.brandBlue,
                              inactiveTrackColor: AppColors.bgSurface,
                              thumbColor: AppColors.brandBlue,
                              overlayColor: AppColors.brandBlue.withValues(alpha: 0.1),
                              trackHeight: 6,
                            ),
                            child: Slider(value: _angle, min: 0, max: 180, onChanged: (v) => setState(() => _angle = v)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Overlap Slider
                    BrandCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Pass Overlap', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              Text('${_overlap.round()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                            ],
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppColors.brandPurple,
                              inactiveTrackColor: AppColors.bgSurface,
                              thumbColor: AppColors.brandPurple,
                              overlayColor: AppColors.brandPurple.withValues(alpha: 0.1),
                              trackHeight: 6,
                            ),
                            child: Slider(value: _overlap, min: 0, max: 30, onChanged: (v) => setState(() => _overlap = v)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Estimates
                    BrandCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Estimated Time', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                              SizedBox(height: 2),
                              Text('1h 20m', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Battery Needed', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                              const SizedBox(height: 2),
                              Text('~58%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.brandPurple)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Start
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<ActiveTaskBloc>().add(const TaskStarted(
                            taskId: 'task_001',
                            taskType: 'mow',
                            zoneId: 'zone_1',
                            zoneName: 'Front Yard',
                            totalAreaSqM: 142,
                          ));
                          // Simulate progress updates
                          _simulateProgress(context);
                          // Go back to dashboard to see overlay
                          context.go('/dashboard');
                        },
                        icon: const Icon(PhosphorIconsBold.play, size: 20),
                        label: const Text('Start Mowing', style: TextStyle(fontSize: 16)),
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

class _PatternCard extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final String? subtitle;

  const _PatternCard({required this.name, required this.isSelected, required this.onTap, required this.icon, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.brandBlue : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          color: isSelected ? AppColors.blueDim : AppColors.bgCard,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: AppColors.bgSurface,
              ),
              child: Icon(icon, size: 24, color: isSelected ? AppColors.brandBlue : AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.brandPurple : AppColors.textPrimary,
              ),
            ),
            if (subtitle != null)
              Text(subtitle!, style: TextStyle(fontSize: 10, color: AppColors.brandPink)),
          ],
        ),
      ),
    );
  }
}
