import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app/robot_app_controller.dart';
import '../../../core/robot/robot_command_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/flow_ui.dart';

class MowingScreen extends StatelessWidget {
  const MowingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<RobotAppController>();
    final client = context.watch<RobotCommandClient>();

    return FlowScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Row(
              children: [
                FlowBackButton(onPressed: () => context.go('/attachments')),
                const SizedBox(width: 12),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.agriculture_rounded, size: 18),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lawn Mower',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Chore-014 · Front yard',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: client.isConnected
                              ? AppColors.brandOrange
                              : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        client.isConnected ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: client.isConnected
                              ? AppColors.brandOrange
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ValueSlider(
                    label: 'Stripe Angle',
                    valueLabel: '${app.stripeAngle.round()}°',
                    value: app.stripeAngle,
                    min: 0,
                    max: 135,
                    divisions: 3,
                    marks: const ['0°', '45°', '90°', '135°'],
                    onChanged: app.setStripeAngle,
                    onChangeEnd: (value) =>
                        app.setStripeAngle(value, send: true),
                  ),
                  const SizedBox(height: 20),
                  const FlowSectionLabel('Stripe Pattern'),
                  const SizedBox(height: 10),
                  Container(
                    height: 43,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _PatternButton(
                            label: 'Straight',
                            icon: Icons.horizontal_rule_rounded,
                            selected: app.stripePattern == 'straight',
                            onTap: () => app.setStripePattern('straight'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _PatternButton(
                            label: 'Checker',
                            icon: Icons.grid_view_rounded,
                            selected: app.stripePattern == 'checker',
                            onTap: () => app.setStripePattern('checker'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ValueSlider(
                    label: 'Height of Cut',
                    valueLabel: '${app.cutHeightMm.round()}mm',
                    value: app.cutHeightMm,
                    min: 20,
                    max: 80,
                    divisions: 4,
                    marks: const ['20mm', '35mm', '50mm', '65mm', '80mm'],
                    onChanged: app.setCutHeight,
                    onChangeEnd: (value) => app.setCutHeight(value, send: true),
                  ),
                  const SizedBox(height: 20),
                  const FlowSectionLabel('Zone'),
                  const SizedBox(height: 10),
                  FlowPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: app.zoneId,
                        isExpanded: true,
                        dropdownColor: AppColors.bgCard,
                        icon: const Icon(
                          Icons.expand_more_rounded,
                          color: AppColors.textMuted,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'zone_1',
                            child: _ZoneLabel('Zone 1'),
                          ),
                          DropdownMenuItem(
                            value: 'zone_2',
                            child: _ZoneLabel('Zone 2'),
                          ),
                          DropdownMenuItem(
                            value: 'zone_3',
                            child: _ZoneLabel('Zone 3'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          app.setZone(value, 'Zone ${value.split('_').last}');
                        },
                      ),
                    ),
                  ),
                  if (app.schedule != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Scheduled for ${app.schedule!.formattedTime}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.brandOrange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      footer: FlowFooter(
        child: Row(
          children: [
            Expanded(
              child: FlowPrimaryButton(
                label: app.schedule == null ? 'Schedule' : 'Scheduled',
                backgroundColor: AppColors.bgSurface,
                onPressed: () => context.push('/schedule'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FlowPrimaryButton(
                label: 'Start',
                icon: Icons.play_arrow_rounded,
                onPressed: () {
                  app.startMowing();
                  context.go('/active-task');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueSlider extends StatelessWidget {
  const _ValueSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.marks,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final List<String> marks;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FlowSectionLabel(
          label,
          trailing: Text(
            valueLabel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.brandOrange,
            ),
          ),
        ),
        const SizedBox(height: 8),
        FlowPanel(
          padding: const EdgeInsets.fromLTRB(10, 17, 10, 14),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.brandOrange,
                  inactiveTrackColor: AppColors.bgSurface,
                  thumbColor: AppColors.brandOrange,
                  overlayColor: AppColors.orangeDim,
                  trackHeight: 4,
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  label: valueLabel,
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: marks
                      .map(
                        (mark) => Text(
                          mark,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PatternButton extends StatelessWidget {
  const _PatternButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneLabel extends StatelessWidget {
  const _ZoneLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.brandOrange,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
