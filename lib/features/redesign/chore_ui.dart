import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

const choreOrange = Color(0xFFFF8400);
const choreSurface = Color(0xFF0E0E10);
const choreBorder = Color(0xFF242429);
const choreMuted = Color(0xFF9E9EA8);
const flowAssets = 'assets/images/attachment_flow/';

TextStyle choreText(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = const Color(0xFFF5F5F7),
}) => TextStyle(
  fontFamily: 'Poppins',
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: 0,
);

void showChoreMessage(BuildContext context, String title, String message) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: choreSurface,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: choreText(18, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(message, style: choreText(13, color: choreMuted)),
          ],
        ),
      ),
    ),
  );
}

class ChoreFrame extends StatelessWidget {
  const ChoreFrame({
    super.key,
    required this.body,
    this.title,
    this.back = '/home',
    this.home = false,
  });
  final Widget body;
  final String? title;
  final String back;
  final bool home;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            children: [
              if (kIsWeb) const _PreviewStatusBar(),
              SizedBox(
                height: 54,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (home)
                        SizedBox(
                          width: 124,
                          height: 42,
                          child: ClipRect(
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  width: 124,
                                  height: 48.5,
                                  child: Image.asset(
                                    'assets/logo/chore-robotics-full-dark.png',
                                    fit: BoxFit.fill,
                                    semanticLabel: 'Chore Robotics',
                                  ),
                                ),
                                const Positioned(
                                  left: 40,
                                  top: 32,
                                  right: 0,
                                  bottom: 0,
                                  child: ColoredBox(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        SizedBox(
                          width: 30,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            tooltip: 'Back',
                            onPressed: () => context.go(back),
                            icon: const Icon(
                              Icons.chevron_left,
                              color: choreOrange,
                              size: 24,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            title ?? '',
                            style: choreText(18, weight: FontWeight.w700),
                          ),
                        ),
                      ],
                      if (home) const Spacer(),
                      SizedBox(
                        width: 42,
                        height: 44,
                        child: IconButton(
                          tooltip: 'Notifications',
                          onPressed: () => showChoreMessage(
                            context,
                            'Notifications',
                            'No new notifications.',
                          ),
                          padding: EdgeInsets.zero,
                          icon: Stack(
                            alignment: Alignment.center,
                            children: [
                              SvgPicture.asset(
                                '${flowAssets}bell-ring.svg',
                                width: 29,
                                height: 30,
                              ),
                              Icon(
                                PhosphorIcons.bell,
                                size: 22,
                                color: Colors.white,
                              ),
                              Positioned(
                                top: 2,
                                right: 0,
                                child: SvgPicture.asset(
                                  '${flowAssets}notification-dot.svg',
                                  width: 4,
                                  height: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: body),
              const ChoreNavigation(),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PreviewStatusBar extends StatelessWidget {
  const _PreviewStatusBar();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(23, 12, 24, 12),
    child: SizedBox(
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SvgPicture.asset(
            '${flowAssets}status-time.svg',
            width: 44,
            height: 16,
          ),
          SvgPicture.asset(
            '${flowAssets}status-icons.svg',
            width: 66.662,
            height: 11.336,
          ),
        ],
      ),
    ),
  );
}

class ChoreNavigation extends StatelessWidget {
  const ChoreNavigation({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 92,
    margin: const EdgeInsets.fromLTRB(24, 0, 20, 28),
    decoration: BoxDecoration(
      color: choreSurface,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: choreBorder),
    ),
    child: Row(
      children: [
        _item('Home', PhosphorIcons.house, () => context.go('/home')),
        _item(
          'Attachments',
          PhosphorIcons.paperclip,
          () => context.go('/attachments'),
        ),
        _item(
          'Map',
          PhosphorIcons.mapTrifold,
          () => showChoreMessage(context, 'Map', 'No map available.'),
        ),
        _item('Settings', PhosphorIcons.gear, () => context.go('/connection')),
      ],
    ),
  );

  Widget _item(String label, IconData icon, VoidCallback onTap) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: choreMuted),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: choreMuted,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    ),
  );
}

class ChorePill extends StatelessWidget {
  const ChorePill(
    this.label, {
    super.key,
    required this.onPressed,
    this.width = 89,
    this.height = 23,
    this.fontSize,
  });
  final String label;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final double? fontSize;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: 44,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: Colors.white,
      ),
      child: Container(
        height: height,
        width: width,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: choreSurface,
          border: Border.all(
            color: onPressed == null ? choreBorder : choreOrange,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          label,
          style: choreText(
            fontSize ?? (height > 30 ? 15 : 12),
            weight: FontWeight.w700,
            color: onPressed == null ? choreMuted : Colors.white,
          ),
        ),
      ),
    ),
  );
}
