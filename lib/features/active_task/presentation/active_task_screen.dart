import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app/robot_app_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/flow_ui.dart';

class ActiveTaskScreen extends StatelessWidget {
  const ActiveTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<RobotAppController>();
    final paused = app.taskStatus == RobotTaskStatus.paused;
    final active = app.hasActiveTask;

    return FlowScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Row(
              children: [
                FlowBackButton(onPressed: () => context.go('/mower')),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleLabel(app.taskStatus),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Live robot task',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child: Column(
                children: [
                  Text(
                    '${app.zoneName}  ·  ${_titleCase(app.stripePattern)} pattern  ·  ${app.cutHeightMm.round()}mm',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 196,
                    height: 196,
                    child: CustomPaint(
                      painter: _ProgressRingPainter(app.progressPercent / 100),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${app.progressPercent.round()}%',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'COMPLETE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    app.formattedElapsed,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Elapsed time',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 18),
                  FlowPanel(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                label: 'Area complete',
                                value:
                                    '${app.completedAreaSqM.toStringAsFixed(1)} m²',
                              ),
                            ),
                            Expanded(
                              child: _Metric(
                                label: 'Total area',
                                value:
                                    '${app.totalAreaSqM.toStringAsFixed(0)} m²',
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1, color: AppColors.border),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                label: 'Battery used',
                                value:
                                    '${app.batteryUsedPercent.toStringAsFixed(1)}%',
                              ),
                            ),
                            Expanded(
                              child: _Metric(
                                label: 'Task status',
                                value: _statusLabel(app.taskStatus),
                                accent: paused,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: FlowPrimaryButton(
                          label: paused ? 'Resume' : 'Pause',
                          icon: paused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          backgroundColor: AppColors.bgSurface,
                          onPressed: active
                              ? () {
                                  if (paused) {
                                    app.resumeTask();
                                  } else {
                                    app.pauseTask();
                                  }
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FlowPrimaryButton(
                          label: active ? 'Cancel' : 'Close',
                          icon: Icons.close_rounded,
                          backgroundColor: AppColors.bgSurface,
                          onPressed: () {
                            if (active) app.cancelTask();
                            context.go('/mower');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      footer: FlowFooter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlowPrimaryButton(
              label: 'Emergency Stop',
              icon: Icons.emergency_rounded,
              backgroundColor: AppColors.accentRed,
              onPressed: active
                  ? () {
                      app.emergencyStop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Task cancelled. Robot motion and blades halted.',
                          ),
                        ),
                      );
                    }
                  : null,
            ),
            const SizedBox(height: 7),
            const Text(
              'Halts blades and motion immediately',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  static String _titleCase(String value) =>
      '${value[0].toUpperCase()}${value.substring(1)}';

  static String _titleLabel(RobotTaskStatus status) => switch (status) {
    RobotTaskStatus.idle => 'Mower ready',
    RobotTaskStatus.running => 'Mowing in progress',
    RobotTaskStatus.paused => 'Mowing paused',
    RobotTaskStatus.completed => 'Mowing complete',
    RobotTaskStatus.cancelled => 'Mowing cancelled',
    RobotTaskStatus.stopped => 'Emergency stop activated',
  };

  static String _statusLabel(RobotTaskStatus status) => switch (status) {
    RobotTaskStatus.idle => 'Idle',
    RobotTaskStatus.running => 'Running',
    RobotTaskStatus.paused => 'Paused',
    RobotTaskStatus.completed => 'Complete',
    RobotTaskStatus.cancelled => 'Cancelled',
    RobotTaskStatus.stopped => 'Stopped',
  };
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: accent ? AppColors.brandOrange : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const start = -math.pi / 2;
    final background = Paint()
      ..color = AppColors.bgSurface
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final foreground = Paint()
      ..color = AppColors.brandOrange
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, background);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
