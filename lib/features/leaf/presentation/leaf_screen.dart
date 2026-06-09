import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../active_task/bloc/active_task_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/connection_bar.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/brand_badge.dart';
import '../../../core/widgets/brand_back_button.dart';
import '../../../core/widgets/toggle_group.dart';

class LeafScreen extends StatefulWidget {
  const LeafScreen({super.key});

  @override
  State<LeafScreen> createState() => _LeafScreenState();
}

class _LeafScreenState extends State<LeafScreen> {
  int _mode = 1; // 0=Full Zone, 1=Spot Clean
  int _collection = 1; // 0=Mulch, 1=Bag

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            const ConnectionBar(batteryPercent: 72),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const BrandBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Leaf Collection', style: Theme.of(context).textTheme.headlineLarge),
                        const Text('Select area to clean', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
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
                    // Attachment
                    BrandCard(
                      borderColor: AppColors.accentOrange.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: AppColors.bgSurface),
                            child: const Icon(PhosphorIconsBold.leaf, size: 20, color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Leaf Collector Attached', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                Text('ATT-5A3B-1C2D', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                          const BrandBadge(label: 'Ready', variant: BadgeVariant.orange, showDot: true),
                        ],
                      ),
                    ).animate().fadeIn(duration: 200.ms),
                    const SizedBox(height: 12),
                    // Mode toggle
                    ToggleGroup(
                      options: const ['Full Zone', 'Spot Clean'],
                      selectedIndex: _mode,
                      onChanged: (i) => setState(() => _mode = i),
                    ),
                    const SizedBox(height: 12),
                    // Mini map placeholder
                    BrandCard(
                      padding: EdgeInsets.zero,
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.bgSurface,
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(PhosphorIconsBold.mapTrifold, size: 32, color: AppColors.textMuted),
                                  const SizedBox(height: 8),
                                  Text('SPOT CLEAN ~18 m²', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accentOrange)),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.bgPrimary.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Tap to add vertices', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 12),
                    // Collection Mode
                    Text('COLLECTION MODE', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _collection = 0),
                            child: BrandCard(
                              selected: _collection == 0,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Text('🌿', style: TextStyle(fontSize: 28)),
                                  const SizedBox(height: 8),
                                  const Text('Mulch', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  const Text('Chop finely,\nleave on lawn', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _collection = 1),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _collection == 1 ? AppColors.accentOrange : AppColors.border),
                                color: _collection == 1 ? AppColors.orangeDim : AppColors.bgCard,
                              ),
                              child: Column(
                                children: [
                                  const Text('🗑', style: TextStyle(fontSize: 28)),
                                  const SizedBox(height: 8),
                                  Text('Collect to Bag', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _collection == 1 ? AppColors.accentOrange : AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  const Text('Fill bag, dump\nat marked point', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                              Text('12 min', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Bag Capacity', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                              const SizedBox(height: 2),
                              Text('~2 dumps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.accentOrange)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentOrange),
                        onPressed: () { context.read<ActiveTaskBloc>().add(const TaskStarted(taskId: 'task_003', taskType: 'collect', zoneId: 'zone_oak', zoneName: 'Under Oak', totalAreaSqM: 18)); context.go('/dashboard'); },
                        icon: const Text('🍂', style: TextStyle(fontSize: 18)),
                        label: const Text('Start Collection', style: TextStyle(fontSize: 16)),
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
