import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/joystick_widget.dart';
import '../../../core/widgets/estop_button.dart';

class MapScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const MapScreen({super.key, this.onBack});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _activeZoneType = 0; // 0=mow, 1=snow, 2=leaf, 3=noGo
  final _zoneTypes = ['Mow', 'Snow', 'Leaf', 'No-Go'];
  final _zoneColors = [AppColors.statusGreen, AppColors.brandBlue, AppColors.accentOrange, AppColors.accentRed];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.bgSecondary,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  // Connection + title
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                          widget.onBack?.call();
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_back, size: 20, color: AppColors.textSecondary),
                        ),
                      ),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.statusGreen)),
                      const SizedBox(width: 6),
                      const Text('Local', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      const Text('Map Your Yard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Spacer(),
                  // Zone type selector
                  Row(
                    children: List.generate(_zoneTypes.length, (i) {
                      final isActive = i == _activeZoneType;
                      return GestureDetector(
                        onTap: () => setState(() => _activeZoneType = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: isActive ? _zoneColors[i].withValues(alpha: 0.12) : Colors.transparent,
                            border: Border.all(
                              color: isActive ? _zoneColors[i] : AppColors.border,
                              width: isActive ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            '${i == 3 ? "✕" : "●"} ${_zoneTypes[i]}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive ? _zoneColors[i] : AppColors.textMuted,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Undo + Done
                  Row(
                    children: [
                      _TopBarButton(label: 'Undo', filled: false),
                      const SizedBox(width: 6),
                      _TopBarButton(label: 'Done', filled: true),
                    ],
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Left: Joystick + Drop Pin
                      Container(
                        width: 220,
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            JoystickWidget(size: 150, label: 'DRIVE ALONG BOUNDARY'),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(PhosphorIconsBold.mapPin, size: 16),
                                label: const Text('Drop Pin'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Center: Map Canvas
                      Expanded(
                        child: Stack(
                          children: [
                            // Grid background
                            Container(
                              color: AppColors.bgSurface,
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: _GridPainter(),
                              ),
                            ),
                            // Zone polygons (placeholder rendering)
                            CustomPaint(
                              size: Size.infinite,
                              painter: _ZonePainter(),
                            ),
                            // Zone info overlay (top right)
                            Positioned(
                              top: 10,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.bgPrimary.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Zones Defined', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text('● Mow: 1', style: TextStyle(fontSize: 10, color: AppColors.statusGreen)),
                                        const SizedBox(width: 10),
                                        Text('● Snow: 1', style: TextStyle(fontSize: 10, color: AppColors.brandBlue)),
                                        const SizedBox(width: 10),
                                        Text('● Leaf: 1', style: TextStyle(fontSize: 10, color: AppColors.accentOrange)),
                                        const SizedBox(width: 10),
                                        Text('✕ No-Go: 1', style: TextStyle(fontSize: 10, color: AppColors.accentRed)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Action hint (bottom left)
                            Positioned(
                              bottom: 10,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.bgPrimary.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  '● Drawing ${_zoneTypes[_activeZoneType]} Zone — 5 pins placed',
                                  style: TextStyle(fontSize: 10, color: _zoneColors[_activeZoneType]),
                                ),
                              ),
                            ),
                            // Scale indicator (bottom right)
                            Positioned(
                              bottom: 10,
                              right: 12,
                              child: Row(
                                children: [
                                  Container(width: 40, height: 2, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  const Text('5m', style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontFamily: 'monospace')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // E-Stop
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(width: 280, child: EStopButton(onActivated: () {})),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final String label;
  final bool filled;
  const _TopBarButton({required this.label, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: filled ? AppColors.brandBlue : AppColors.bgCard,
        border: filled ? null : Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: filled ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ZonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Mow zone (green)
    _drawZone(canvas, [
      Offset(size.width * 0.05, size.height * 0.08),
      Offset(size.width * 0.85, size.height * 0.05),
      Offset(size.width * 0.9, size.height * 0.5),
      Offset(size.width * 0.8, size.height * 0.85),
      Offset(size.width * 0.1, size.height * 0.88),
      Offset(size.width * 0.05, size.height * 0.55),
    ], AppColors.statusGreen, 'MOW ZONE 1 — 142 m²');

    // No-go zone (red)
    _drawZone(canvas, [
      Offset(size.width * 0.3, size.height * 0.22),
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.51, size.height * 0.45),
      Offset(size.width * 0.29, size.height * 0.47),
    ], AppColors.accentRed, 'NO-GO');

    // Leaf zone (orange)
    _drawZone(canvas, [
      Offset(size.width * 0.62, size.height * 0.5),
      Offset(size.width * 0.85, size.height * 0.48),
      Offset(size.width * 0.86, size.height * 0.78),
      Offset(size.width * 0.63, size.height * 0.8),
    ], AppColors.accentOrange, 'LEAF');

    // Robot position (animated blue dot)
    final robotPos = Offset(size.width * 0.2, size.height * 0.7);
    canvas.drawCircle(robotPos, 12, Paint()..color = AppColors.brandBlue.withValues(alpha: 0.15));
    canvas.drawCircle(robotPos, 5, Paint()..color = AppColors.brandBlue);

    // Dock icon
    final dockRect = Rect.fromCenter(center: Offset(size.width * 0.45, size.height * 0.78), width: 26, height: 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(dockRect, const Radius.circular(3)),
      Paint()..color = AppColors.brandBlue.withValues(alpha: 0.8),
    );
  }

  void _drawZone(Canvas canvas, List<Offset> points, Color color, String label) {
    final path = Path()..addPolygon(points, true);

    // Fill
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.08));
    // Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Vertices
    for (final p in points) {
      canvas.drawCircle(p, 5, Paint()..color = color);
      canvas.drawCircle(p, 5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.6)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final center = points.reduce((a, b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2));
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
