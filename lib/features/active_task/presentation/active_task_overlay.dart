import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/active_task_bloc.dart';

/// Floating overlay shown on dashboard when a task is active, paused, or stuck.
/// Shows progress, area, time, and Resume/Cancel actions.
class ActiveTaskOverlay extends StatelessWidget {
  const ActiveTaskOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveTaskBloc, ActiveTaskState>(
      builder: (context, state) {
        if (state.status == TaskStatus.idle || state.status == TaskStatus.completed) {
          return const SizedBox.shrink();
        }
        return _TaskCard(state: state);
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final ActiveTaskState state;
  const _TaskCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: task type + status badge
          Row(
            children: [
              _TaskIcon(taskType: state.taskType ?? 'mow', status: state.status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _taskLabel,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Text(
                      state.zoneName ?? 'Zone',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: state.status, failReason: state.failReason),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Stack(
              children: [
                Container(height: 8, color: AppColors.bgSurface),
                FractionallySizedBox(
                  widthFactor: (state.progressPercent / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: _progressGradient,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: 'Progress', value: '${state.progressPercent.toStringAsFixed(0)}%', color: AppColors.brandBlue),
              _Stat(label: 'Area', value: '${state.completedAreaSqM.toStringAsFixed(0)} / ${state.totalAreaSqM.toStringAsFixed(0)} m²'),
              _Stat(label: 'Elapsed', value: state.formattedElapsed),
              _Stat(label: 'ETA', value: state.formattedRemaining, color: AppColors.brandPurple),
            ],
          ),

          // Action buttons (only when paused/stuck/failed)
          if (state.canResume) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                // Resume button
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => context.read<ActiveTaskBloc>().add(TaskResumed()),
                      icon: const Icon(PhosphorIconsBold.play, size: 16),
                      label: const Text('Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Cancel button
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => context.read<ActiveTaskBloc>().add(TaskCancelled()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentRed,
                        side: BorderSide(color: AppColors.accentRed.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (state.status == TaskStatus.running) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.read<ActiveTaskBloc>().add(TaskPaused()),
                icon: const Icon(PhosphorIconsBold.pause, size: 16),
                label: const Text('Pause Task'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandPurple,
                  side: BorderSide(color: AppColors.brandPurple.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }

  String get _taskLabel => switch (state.taskType) {
    'mow' => 'Mowing',
    'plow' => 'Snow Plowing',
    'collect' => 'Leaf Collection',
    _ => 'Task',
  };

  Color get _borderColor => switch (state.status) {
    TaskStatus.running => AppColors.brandBlue.withValues(alpha: 0.2),
    TaskStatus.paused => AppColors.brandPurple.withValues(alpha: 0.2),
    TaskStatus.stuck => AppColors.accentYellow.withValues(alpha: 0.3),
    TaskStatus.failed => AppColors.accentRed.withValues(alpha: 0.3),
    _ => AppColors.border,
  };

  LinearGradient get _progressGradient => switch (state.status) {
    TaskStatus.running => const LinearGradient(colors: [AppColors.brandBlue, AppColors.brandPurple]),
    TaskStatus.paused => LinearGradient(colors: [AppColors.brandPurple, AppColors.brandPurple.withValues(alpha: 0.6)]),
    TaskStatus.stuck => const LinearGradient(colors: [AppColors.accentYellow, AppColors.accentOrange]),
    TaskStatus.failed => const LinearGradient(colors: [AppColors.accentRed, AppColors.accentOrange]),
    _ => const LinearGradient(colors: [AppColors.brandBlue, AppColors.brandPurple]),
  };
}

class _TaskIcon extends StatelessWidget {
  final String taskType;
  final TaskStatus status;
  const _TaskIcon({required this.taskType, required this.status});

  @override
  Widget build(BuildContext context) {
    final icon = switch (taskType) {
      'mow' => PhosphorIconsBold.plant,
      'plow' => PhosphorIconsBold.snowflake,
      'collect' => PhosphorIconsBold.leaf,
      _ => PhosphorIconsBold.robot,
    };

    final color = switch (status) {
      TaskStatus.running => AppColors.brandBlue,
      TaskStatus.paused => AppColors.brandPurple,
      TaskStatus.stuck => AppColors.accentYellow,
      TaskStatus.failed => AppColors.accentRed,
      _ => AppColors.textMuted,
    };

    Widget iconWidget = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.12),
      ),
      child: Icon(icon, size: 20, color: color),
    );

    // Pulse animation when running
    if (status == TaskStatus.running) {
      iconWidget = iconWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1000.ms);
    }

    // Shake when stuck
    if (status == TaskStatus.stuck) {
      iconWidget = iconWidget
          .animate(onPlay: (c) => c.repeat())
          .shake(hz: 3, rotation: 0.03, duration: 500.ms)
          .then(delay: 1500.ms);
    }

    return iconWidget;
  }
}

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;
  final String? failReason;
  const _StatusBadge({required this.status, this.failReason});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      TaskStatus.running => ('Running', AppColors.brandBlue.withValues(alpha: 0.12), AppColors.brandBlue),
      TaskStatus.paused => ('Paused', AppColors.brandPurple.withValues(alpha: 0.12), AppColors.brandPurple),
      TaskStatus.stuck => ('Stuck', AppColors.accentYellow.withValues(alpha: 0.12), AppColors.accentYellow),
      TaskStatus.failed => (failReason ?? 'Failed', AppColors.accentRed.withValues(alpha: 0.12), AppColors.accentRed),
      _ => ('', Colors.transparent, Colors.transparent),
    };

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );

    if (status == TaskStatus.running) {
      badge = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: fg))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 800.ms)
              .then()
              .fadeOut(duration: 800.ms),
          const SizedBox(width: 6),
          badge,
        ],
      );
    }

    return badge;
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary, fontFamily: 'monospace')),
      ],
    );
  }
}
