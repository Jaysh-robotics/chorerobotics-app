import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../active_task/bloc/active_task_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/robot/robot_command_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/connection_bar.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/brand_badge.dart';
import '../../../core/widgets/brand_back_button.dart';
import '../../../core/widgets/toggle_group.dart';

class SnowScreen extends StatefulWidget {
  const SnowScreen({super.key});

  @override
  State<SnowScreen> createState() => _SnowScreenState();
}

class _SnowScreenState extends State<SnowScreen> {
  int _startFrom = 0;
  int _depth = 0;
  int _disposal = 0;

  static const _startOptions = [
    ('driveway_entrance', 'Driveway Entrance', 'Pushes snow toward back/sides'),
    ('garage_door', 'Garage Door', 'Pushes snow toward the street'),
    ('center', 'Center', 'Pushes snow to both sides'),
    ('custom_point', 'Custom Point', 'Tap on map to pick start'),
  ];

  static const _depthOptions = [
    ('light', '< 5cm'),
    ('medium', '5-15cm'),
    ('heavy', '> 15cm'),
  ];

  static const _disposalOptions = [
    ('push_left', 'Push Left'),
    ('push_right', 'Push Right'),
    ('pile_zone', 'Pile Zone'),
  ];

  String get _selectedStartFrom => _startOptions[_startFrom].$1;
  String get _selectedDepth => _depthOptions[_depth].$1;
  String get _selectedDisposal => _disposalOptions[_disposal].$1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            const ConnectionBar(batteryPercent: 85),
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
                        Text(
                          'Snow Plowing',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const Text(
                          'Driveway — 38 m²',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
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
                      borderColor: AppColors.brandBlue.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.bgSurface,
                            ),
                            child: const Icon(
                              PhosphorIconsBold.snowflake,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Snow Plow Attached',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'ATT-2C4D-6E8F',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const BrandBadge(
                            label: 'Ready',
                            variant: BadgeVariant.blue,
                            showDot: true,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 200.ms),
                    const SizedBox(height: 16),
                    // Start From
                    Text(
                      'START FROM',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 10),
                    ..._buildStartOptions(),
                    const SizedBox(height: 16),
                    // Snow Depth
                    Text(
                      'SNOW DEPTH',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 10),
                    ToggleGroup(
                      options: const [
                        'Light\n< 5cm',
                        'Medium\n5-15cm',
                        'Heavy\n> 15cm',
                      ],
                      selectedIndex: _depth,
                      onChanged: (i) => setState(() => _depth = i),
                    ),
                    const SizedBox(height: 16),
                    // Disposal
                    Text(
                      'SNOW DISPOSAL',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _DisposalOption(
                          icon: PhosphorIconsBold.arrowLeft,
                          label: 'Push Left',
                          isSelected: _disposal == 0,
                          onTap: () => setState(() => _disposal = 0),
                        ),
                        const SizedBox(width: 8),
                        _DisposalOption(
                          icon: PhosphorIconsBold.arrowRight,
                          label: 'Push Right',
                          isSelected: _disposal == 1,
                          onTap: () => setState(() => _disposal = 1),
                        ),
                        const SizedBox(width: 8),
                        _DisposalOption(
                          icon: PhosphorIconsBold.mapPin,
                          label: 'Pile Zone',
                          isSelected: _disposal == 2,
                          onTap: () => setState(() => _disposal = 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Estimates
                    BrandCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated Time',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '25 min',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Passes',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '1 pass',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandBlue,
                                ),
                              ),
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
                        onPressed: () {
                          const taskId = 'task_002';
                          const zoneId = 'zone_driveway';
                          const zoneName = 'Driveway';
                          const totalAreaSqM = 38.0;
                          context.read<RobotCommandClient>().sendTaskStart(
                            taskId: taskId,
                            taskType: 'plow',
                            zoneId: zoneId,
                            zoneName: zoneName,
                            totalAreaSqM: totalAreaSqM,
                            parameters: {
                              'start_from': _selectedStartFrom,
                              'snow_depth': _selectedDepth,
                              'snow_depth_range': _depthOptions[_depth].$2,
                              'snow_disposal': _selectedDisposal,
                            },
                          );
                          context.read<ActiveTaskBloc>().add(
                            const TaskStarted(
                              taskId: taskId,
                              taskType: 'plow',
                              zoneId: zoneId,
                              zoneName: zoneName,
                              totalAreaSqM: totalAreaSqM,
                            ),
                          );
                          context.go('/dashboard');
                        },
                        icon: const Icon(PhosphorIconsBold.snowflake, size: 18),
                        label: const Text(
                          'Start Plowing',
                          style: TextStyle(fontSize: 16),
                        ),
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

  List<Widget> _buildStartOptions() {
    return List.generate(_startOptions.length, (i) {
      final isSelected = i == _startFrom;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () => setState(() => _startFrom = i),
          child: BrandCard(
            selected: isSelected,
            gradient: isSelected
                ? LinearGradient(colors: [AppColors.blueDim, AppColors.blueDim])
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brandBlue
                          : AppColors.borderActive,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.brandBlue,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _startOptions[i].$2,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _startOptions[i].$3,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _DisposalOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DisposalOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.brandBlue : AppColors.border,
            ),
            color: isSelected ? AppColors.blueDim : AppColors.bgCard,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.brandBlue : AppColors.textPrimary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.brandBlue
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
