import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/robot/robot_command_client.dart';

import 'chore_ui.dart';
import 'weather_status.dart';

class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key});
  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: Image.asset(
        '${flowAssets}splash-logo.png',
        width: 131,
        height: 142,
        semanticLabel: 'Chore Robotics',
      ),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheduleEnabled = context.select<RobotCommandClient, bool>(
      (client) => client.mowerScheduleEnabled,
    );
    return ChoreFrame(
      home: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GOOD MORNING',
                        style: choreText(18, weight: FontWeight.w700),
                      ),
                      Text(
                        'Let\u2019s get to work.',
                        style: choreText(
                          22,
                          weight: FontWeight.w700,
                          color: choreOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const WeatherStatus(),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: MediaQuery.sizeOf(context).width < 360 ? 108 : 72,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: choreSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: choreBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const _CroppedAsset(
                          'battery.png',
                          width: 22,
                          height: 38,
                          scaleX: 3.1374,
                          scaleY: 2.3333,
                          offsetX: -1.0651,
                          offsetY: -.6582,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Battery Health',
                                style: choreText(9, weight: FontWeight.w200),
                              ),
                              Text(
                                '82%',
                                style: choreText(13, weight: FontWeight.w700),
                              ),
                              Text(
                                'Est. 4 hrs remaining',
                                style: choreText(
                                  6,
                                  color: const Color(0xFF77777B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(
                    width: 30,
                    thickness: 1,
                    color: Color(0xFF454548),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF50D111),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Current Status',
                                style: choreText(9, weight: FontWeight.w200),
                              ),
                              Text(
                                'Ready',
                                style: choreText(13, weight: FontWeight.w700),
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
            const SizedBox(height: 28),
            Center(
              child: ChorePill(
                'Configure New Attachment',
                width: 275,
                height: 36,
                fontSize: 12,
                onPressed: () => context.go('/attachment-setup'),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              decoration: BoxDecoration(
                color: choreSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: choreBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Schedule',
                    style: choreText(13, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFF77777B),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Wed, 8:00 AM \u2022 Mower \u2022 Front Yard',
                    style: choreText(10, weight: FontWeight.w200),
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFF454548),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Image.asset(
                        '${flowAssets}mower-ready.png',
                        width: 58,
                        height: 40,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        semanticLabel: 'Chore Mower',
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Chore Mower',
                          style: choreText(11, weight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Semantics(
                          label: 'Enable mower schedule',
                          toggled: scheduleEnabled,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context
                                .read<RobotCommandClient>()
                                .setMowerScheduleEnabled(!scheduleEnabled),
                            child: ExcludeSemantics(
                              child: IgnorePointer(
                                child: Transform.scale(
                                  scale: .6,
                                  alignment: Alignment.centerRight,
                                  child: Switch(
                                    value: scheduleEnabled,
                                    onChanged: context
                                        .read<RobotCommandClient>()
                                        .setMowerScheduleEnabled,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: choreOrange,
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: const Color(0xFF454548),
                                    trackOutlineColor:
                                        const WidgetStatePropertyAll(
                                          Colors.transparent,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ChorePill(
                'Re-run: Chore Mower | Front Yard',
                width: 275,
                height: 36,
                fontSize: 12,
                onPressed: () {
                  final client = context.read<RobotCommandClient>();
                  client.sendTaskStart(
                    taskId: 'mow-${DateTime.now().millisecondsSinceEpoch}',
                    taskType: 'mow',
                    zoneId: 'zone_1',
                    zoneName: 'Front Yard',
                    totalAreaSqM: 142,
                    parameters: const {'pattern': 'straight'},
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        client.isConnected
                            ? 'Mowing request sent to server.'
                            : 'Offline preview: connect to a server to re-run mowing.',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CroppedAsset extends StatelessWidget {
  const _CroppedAsset(
    this.name, {
    required this.width,
    required this.height,
    required this.scaleX,
    required this.scaleY,
    required this.offsetX,
    required this.offsetY,
  });
  final String name;
  final double width, height, scaleX, scaleY, offsetX, offsetY;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: ClipRect(
      child: Stack(
        children: [
          Positioned(
            left: width * offsetX,
            top: height * offsetY,
            width: width * scaleX,
            height: height * scaleY,
            child: Image.asset('$flowAssets$name', fit: BoxFit.fill),
          ),
        ],
      ),
    ),
  );
}
