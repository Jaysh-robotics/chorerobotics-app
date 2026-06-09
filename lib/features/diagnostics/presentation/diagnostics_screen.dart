import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/connection_bar.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/metric_row.dart';
import '../../../core/widgets/toggle_group.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const ConnectionBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Diagnostics', style: Theme.of(context).textTheme.headlineLarge),
                    const Text('System Health & Logs', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                    color: AppColors.bgCard,
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIconsBold.export, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      const Text('Export', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
              child: Column(
                children: [
                  ToggleGroup(
                    options: const ['Overview', 'Technical', 'Faults'],
                    selectedIndex: _tabIndex,
                    onChanged: (i) => setState(() => _tabIndex = i),
                  ),
                  const SizedBox(height: 16),
                  // System Health
                  BrandCard(
                    borderColor: AppColors.brandBlue.withValues(alpha: 0.15),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: AppColors.blueDim,
                              ),
                              child: const Icon(PhosphorIconsBold.checkCircle, size: 22, color: AppColors.brandBlue),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('All Systems Normal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                SizedBox(height: 2),
                                Text('Last checked just now', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        MetricRow(label: 'Motors', value: 'Normal', valueColor: AppColors.brandBlue),
                        const MetricRow(label: 'Blade', value: 'Standby', valueColor: AppColors.textMuted),
                        MetricRow(label: 'Battery Health', value: '94%', valueColor: AppColors.brandPurple),
                        const MetricRow(label: 'Temperature', value: 'Normal'),
                        MetricRow(label: 'Connection', value: 'Strong', valueColor: AppColors.brandBlue),
                        MetricRow(label: 'Data Link', value: 'Active', valueColor: AppColors.brandBlue, isLast: true),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 10),
                  // Alerts
                  BrandCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('RECENT ALERTS', style: Theme.of(context).textTheme.labelSmall),
                            const Text('Last 24h', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _AlertEntry(color: AppColors.accentYellow, text: 'Wi-Fi signal dropped briefly', time: '3 hours ago'),
                        _AlertEntry(color: AppColors.accentRed, text: 'Emergency stop activated by user', time: '4 hours ago'),
                        _AlertEntry(color: AppColors.brandBlue, text: 'Emergency stop recovered — all checks passed', time: '4 hours ago', isLast: true),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertEntry extends StatelessWidget {
  final Color color;
  final String text;
  final String time;
  final bool isLast;

  const _AlertEntry({required this.color, required this.text, required this.time, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
