import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app/robot_app_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/flow_ui.dart';

class AttachmentSelectionScreen extends StatelessWidget {
  const AttachmentSelectionScreen({super.key});

  static const _attachments = [
    ('mower', 'Mower', Icons.agriculture_rounded, true),
    ('plow', 'Plow', Icons.landscape_rounded, false),
    ('irrigation', 'Irrigation', Icons.water_drop_outlined, false),
    ('mopping', 'Mopping', Icons.cleaning_services_outlined, false),
    ('sweeper', 'Sweeper', Icons.auto_fix_high_rounded, false),
    ('hauler', 'Hauler', Icons.inventory_2_outlined, false),
    ('leaf_blower', 'Leaf Blower', Icons.air_rounded, false),
    ('snow_blower', 'Snow Blower', Icons.ac_unit_rounded, false),
    ('sprayer', 'Sprayer', Icons.sanitizer_outlined, false),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<RobotAppController>();

    return FlowScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => context.go('/connection'),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.bgCard,
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.router_rounded, size: 20),
                tooltip: 'Server connection',
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "What's attached to your\nChore Robot?",
              style: TextStyle(
                fontSize: 23,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select the attachment currently connected to your robot.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 22),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.13,
              ),
              itemCount: _attachments.length,
              itemBuilder: (context, index) {
                final item = _attachments[index];
                return _AttachmentTile(
                  label: item.$2,
                  icon: item.$3,
                  selected: app.selectedAttachment == item.$1,
                  supported: item.$4,
                  onTap: () {
                    app.selectAttachment(item.$1, supported: item.$4);
                    if (item.$4) {
                      context.go('/mower');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${item.$2} is not available in this build yet.',
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'You can change this later in settings.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      footer: FlowFooter(
        child: FlowPrimaryButton(
          label: 'CONFIRM ATTACHMENT',
          onPressed: () {
            app.selectAttachment('mower', supported: true);
            context.go('/mower');
          },
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.supported,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool supported;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: true,
      label: supported ? label : '$label, coming soon',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.brandOrange : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? AppColors.brandOrange : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 23,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
