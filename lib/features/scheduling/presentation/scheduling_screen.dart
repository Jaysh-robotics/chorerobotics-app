import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app/robot_app_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/flow_ui.dart';

class SchedulingScreen extends StatefulWidget {
  const SchedulingScreen({super.key});

  @override
  State<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends State<SchedulingScreen> {
  static const _minutes = [0, 15, 30, 45];
  static const _dayShort = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  late int _hour;
  late int _minute;
  late String _period;
  late Set<int> _days;

  @override
  void initState() {
    super.initState();
    final existing = context.read<RobotAppController>().schedule;
    _hour = existing?.hour ?? 7;
    _minute = existing?.minute ?? 30;
    _period = existing?.period ?? 'AM';
    _days = {...?existing?.days};
    if (_days.isEmpty) _days = {0, 1, 3, 5};
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<RobotAppController>();
    final selectedDays = _days.toList()..sort();

    return FlowScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Row(
              children: [
                FlowBackButton(onPressed: () => context.pop()),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Schedule',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Lawn Mower · Zone 2',
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
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FlowSectionLabel('Start Time'),
                  const SizedBox(height: 10),
                  FlowPanel(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SizedBox(
                      height: 168,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _TimeWheel(
                                  values: [
                                    for (var value = 1; value <= 12; value++)
                                      value.toString().padLeft(2, '0'),
                                  ],
                                  initialIndex: _hour - 1,
                                  onChanged: (index) =>
                                      setState(() => _hour = index + 1),
                                ),
                              ),
                              Expanded(
                                child: _TimeWheel(
                                  values: _minutes
                                      .map(
                                        (value) =>
                                            value.toString().padLeft(2, '0'),
                                      )
                                      .toList(),
                                  initialIndex: _minutes.indexOf(_minute),
                                  onChanged: (index) =>
                                      setState(() => _minute = _minutes[index]),
                                ),
                              ),
                              Expanded(
                                child: _TimeWheel(
                                  values: const ['AM', 'PM'],
                                  initialIndex: _period == 'AM' ? 0 : 1,
                                  onChanged: (index) => setState(
                                    () => _period = index == 0 ? 'AM' : 'PM',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const FlowSectionLabel('Repeat'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final selected = _days.contains(index);
                      return InkWell(
                        onTap: () => setState(() {
                          if (selected) {
                            _days.remove(index);
                          } else {
                            _days.add(index);
                          }
                        }),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.brandOrange
                                : AppColors.bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AppColors.brandOrange
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            _dayShort[index],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _days.isEmpty
                        ? 'Runs once'
                        : 'Every week on ${selectedDays.map((index) => _dayNames[index]).join(', ')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 100,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            size: 20,
                            color: AppColors.brandOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next run: $_hour:${_minute.toString().padLeft(2, '0')} $_period',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${_titleCase(app.stripePattern)} pattern · ${app.cutHeightMm.round()}mm · ${app.zoneName}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      footer: FlowFooter(
        child: FlowPrimaryButton(
          label: 'Set Schedule',
          icon: Icons.check_rounded,
          onPressed: _days.isEmpty
              ? null
              : () {
                  app.saveSchedule(
                    MowerSchedule(
                      hour: _hour,
                      minute: _minute,
                      period: _period,
                      days: _days,
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Schedule saved for $_hour:${_minute.toString().padLeft(2, '0')} $_period.',
                      ),
                    ),
                  );
                  context.pop();
                },
        ),
      ),
    );
  }

  String _titleCase(String value) =>
      '${value[0].toUpperCase()}${value.substring(1)}';
}

class _TimeWheel extends StatelessWidget {
  const _TimeWheel({
    required this.values,
    required this.initialIndex,
    required this.onChanged,
  });

  final List<String> values;
  final int initialIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      itemExtent: 44,
      scrollController: FixedExtentScrollController(initialItem: initialIndex),
      selectionOverlay: const SizedBox.shrink(),
      onSelectedItemChanged: onChanged,
      children: values
          .map(
            (value) => Center(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
