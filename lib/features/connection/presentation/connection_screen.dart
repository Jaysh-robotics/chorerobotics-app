import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/robot/robot_command_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/flow_ui.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: context.read<RobotCommandClient>().serverUrl,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = context.watch<RobotCommandClient>();
    final connected = client.isConnected;

    return FlowScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 34, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.orangeDim,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.router_rounded,
                color: AppColors.brandOrange,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Robot server',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Optional test utility. Connect once here to send commands from every app screen.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 28),
            FlowPanel(
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _statusColor(client.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusLabel(client.status),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'ACK ${client.ackCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const FlowSectionLabel('Server URL'),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              enabled: !connected,
              autocorrect: false,
              keyboardType: TextInputType.url,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'ws://192.168.1.100:8765/ws',
                prefixIcon: const Icon(Icons.link_rounded, size: 20),
                fillColor: AppColors.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            if (client.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                client.errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.accentRed,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FlowPrimaryButton(
                    label: connected ? 'Disconnect' : 'Connect',
                    icon: connected
                        ? Icons.link_off_rounded
                        : Icons.power_rounded,
                    backgroundColor: connected
                        ? AppColors.bgSurface
                        : AppColors.brandOrange,
                    onPressed:
                        client.status == RobotCommandConnectionStatus.connecting
                        ? null
                        : () async {
                            if (connected) {
                              await client.disconnect();
                            } else {
                              await client.connect(_urlController.text);
                            }
                          },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 92,
                  child: FlowPrimaryButton(
                    label: 'Ping',
                    backgroundColor: AppColors.bgSurface,
                    onPressed: connected ? client.sendPing : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              client.lastAck == null
                  ? 'No server response yet'
                  : 'Last ACK: ${client.lastAck!.status} · ${client.lastAck!.receivedAt.toLocal().toString().substring(11, 19)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      footer: FlowFooter(
        child: FlowPrimaryButton(
          label: 'Back to app',
          icon: Icons.apps_rounded,
          backgroundColor: connected
              ? AppColors.brandOrange
              : AppColors.bgSurface,
          onPressed: () => context.go('/home'),
        ),
      ),
    );
  }

  Color _statusColor(RobotCommandConnectionStatus status) => switch (status) {
    RobotCommandConnectionStatus.connected => AppColors.brandOrange,
    RobotCommandConnectionStatus.connecting => AppColors.accentYellow,
    RobotCommandConnectionStatus.error => AppColors.accentRed,
    RobotCommandConnectionStatus.disconnected => AppColors.textMuted,
  };

  String _statusLabel(RobotCommandConnectionStatus status) => switch (status) {
    RobotCommandConnectionStatus.connected => 'Connected to robot server',
    RobotCommandConnectionStatus.connecting => 'Connecting…',
    RobotCommandConnectionStatus.error => 'Connection failed',
    RobotCommandConnectionStatus.disconnected => 'Disconnected',
  };
}
