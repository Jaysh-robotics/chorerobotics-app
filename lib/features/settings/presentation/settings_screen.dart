import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/connection_bar.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/brand_badge.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            const ConnectionBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
                  const Text('Robot & App Configuration', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Robot Info
                    BrandCard(
                      borderColor: AppColors.brandBlue.withValues(alpha: 0.12),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.bgSurface,
                            ),
                            child: const Icon(PhosphorIconsBold.robot, size: 28, color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ChoreBot Alpha', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                                SizedBox(height: 2),
                                Text('Model X1 · CHORE-A1B2-C3D4', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                          const Icon(PhosphorIconsBold.pencilSimple, size: 18, color: AppColors.brandBlue),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Robot Settings
                    Text('ROBOT', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    _SettingsTile(icon: PhosphorIconsBold.info, label: 'Robot Info', subtitle: 'Model, serial number, firmware'),
                    _SettingsTile(icon: PhosphorIconsBold.wifiHigh, label: 'Connection', subtitle: 'Wi-Fi network, BLE auto-connect'),
                    _SettingsTile(icon: PhosphorIconsBold.download, label: 'Firmware Update', subtitle: 'v1.0.0 — Up to date', trailing: const BrandBadge(label: 'Current', variant: BadgeVariant.blue)),
                    _SettingsTile(icon: PhosphorIconsBold.wrench, label: 'Calibration', subtitle: 'Blade, GPS, compass calibration'),

                    const SizedBox(height: 20),
                    Text('APP', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    _SettingsTile(icon: PhosphorIconsBold.bell, label: 'Notifications', subtitle: 'Task complete, errors, battery'),
                    _SettingsTile(icon: PhosphorIconsBold.ruler, label: 'Units', subtitle: 'Metric (m, °C, km/h)'),
                    _SettingsTile(icon: PhosphorIconsBold.moon, label: 'Appearance', subtitle: 'Dark mode'),
                    _SettingsTile(icon: PhosphorIconsBold.textAa, label: 'Text Size', subtitle: 'Default'),

                    const SizedBox(height: 20),
                    Text('ACCOUNT', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    _SettingsTile(icon: PhosphorIconsBold.user, label: 'Account', subtitle: 'jay@chorerobotics.com'),
                    _SettingsTile(icon: PhosphorIconsBold.shieldCheck, label: 'Privacy & Security', subtitle: 'Certificates, data'),
                    _SettingsTile(icon: PhosphorIconsBold.question, label: 'Help & Support', subtitle: 'FAQ, contact'),
                    _SettingsTile(icon: PhosphorIconsBold.fileText, label: 'Legal', subtitle: 'Terms, privacy, licenses'),

                    const SizedBox(height: 20),
                    // Sign out
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(PhosphorIconsBold.signOut, size: 18, color: AppColors.accentRed),
                        label: Text('Sign Out', style: TextStyle(color: AppColors.accentRed)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.accentRed.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text('ChoreRobotics v1.0.0 (1)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({required this.icon, required this.label, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                trailing ?? Icon(PhosphorIconsBold.caretRight, size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
