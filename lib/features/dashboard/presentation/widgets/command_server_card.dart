import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/robot/robot_command_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_card.dart';

class CommandServerCard extends StatefulWidget {
  const CommandServerCard({super.key});

  @override
  State<CommandServerCard> createState() => _CommandServerCardState();
}

class _CommandServerCardState extends State<CommandServerCard> {
  final _client = RobotCommandClient();
  final _urlCtrl = TextEditingController(text: 'ws://192.168.1.100:8765/ws');

  @override
  void initState() {
    super.initState();
    _client.addListener(_onClientChanged);
  }

  @override
  void dispose() {
    _client.removeListener(_onClientChanged);
    _client.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _onClientChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final connected = _client.status == RobotCommandConnectionStatus.connected;
    final connecting =
        _client.status == RobotCommandConnectionStatus.connecting;
    final ack = _client.lastAck;
    final statusColor = switch (_client.status) {
      RobotCommandConnectionStatus.connected => AppColors.statusGreen,
      RobotCommandConnectionStatus.connecting => AppColors.accentYellow,
      RobotCommandConnectionStatus.error => AppColors.accentRed,
      RobotCommandConnectionStatus.disconnected => AppColors.textMuted,
    };
    final statusText = switch (_client.status) {
      RobotCommandConnectionStatus.connected => 'Connected',
      RobotCommandConnectionStatus.connecting => 'Connecting',
      RobotCommandConnectionStatus.error => 'Error',
      RobotCommandConnectionStatus.disconnected => 'Disconnected',
    };

    return BrandCard(
      borderColor: connected
          ? AppColors.statusGreen.withValues(alpha: 0.28)
          : AppColors.brandBlue.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.bgSurface,
                ),
                child: const Icon(
                  PhosphorIconsBold.broadcast,
                  size: 20,
                  color: AppColors.brandBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Command Server',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text(
                      'Phone -> laptop WebSocket demo',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                label: ack == null ? statusText : 'ACK ${_client.ackCount} ✓',
                color: ack == null ? statusColor : AppColors.statusGreen,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: ack == null
                  ? AppColors.bgSurface
                  : AppColors.statusGreen.withValues(alpha: 0.12),
              border: Border.all(
                color: ack == null
                    ? AppColors.border
                    : AppColors.statusGreen.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  ack == null
                      ? PhosphorIconsBold.clock
                      : PhosphorIconsBold.checkCircle,
                  size: 17,
                  color: ack == null
                      ? AppColors.textMuted
                      : AppColors.statusGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ack == null
                        ? 'Waiting for server ACK'
                        : 'Server received ${ack.payload['message'] ?? ack.type}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ack == null
                          ? AppColors.textMuted
                          : AppColors.statusGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlCtrl,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'ws://laptop-ip:8765/ws',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Counter(label: 'Sent', value: _client.sentCount),
              const SizedBox(width: 8),
              _Counter(label: 'ACK', value: _client.ackCount),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _client.lastSentType == null
                      ? 'No command sent yet'
                      : 'Last: ${_client.lastSentType}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: connecting
                      ? null
                      : (connected
                            ? _client.disconnect
                            : () => _client.connect(_urlCtrl.text)),
                  icon: Icon(
                    connected
                        ? PhosphorIconsBold.plugs
                        : PhosphorIconsBold.plug,
                    size: 16,
                  ),
                  label: Text(connected ? 'Disconnect' : 'Connect'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 92,
                child: OutlinedButton(
                  onPressed: connected ? _client.sendPing : null,
                  child: const Text('Ping'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _CommandButton(
                label: 'Forward',
                icon: PhosphorIconsBold.arrowUp,
                onTap: () => _client.sendDirectionalCommand('forward'),
              ),
              const SizedBox(width: 6),
              _CommandButton(
                label: 'Back',
                icon: PhosphorIconsBold.arrowDown,
                onTap: () => _client.sendDirectionalCommand('backward'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _CommandButton(
                label: 'Left',
                icon: PhosphorIconsBold.arrowLeft,
                onTap: () => _client.sendDirectionalCommand('left'),
              ),
              const SizedBox(width: 6),
              _CommandButton(
                label: 'Right',
                icon: PhosphorIconsBold.arrowRight,
                onTap: () => _client.sendDirectionalCommand('right'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _client.sendEStop,
              icon: const Icon(PhosphorIconsBold.warning, size: 16),
              label: const Text('Send E-Stop'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentRed,
                side: BorderSide(
                  color: AppColors.accentRed.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          if (_client.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _client.errorMessage!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.accentRed),
            ),
          ],
          if (_client.lastInboundRaw != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last server reply: ${_client.lastInboundRaw}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;

  const _Counter({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _CommandButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CommandButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 42,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 15),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}
