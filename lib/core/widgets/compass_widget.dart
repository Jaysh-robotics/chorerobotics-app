import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CompassWidget extends StatelessWidget {
  final double heading; // degrees
  final double size;

  const CompassWidget({super.key, this.heading = 45, this.size = 90});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CompassPainter(heading: heading),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double heading;
  _CompassPainter({required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Circle border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Background
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = AppColors.bgSurface,
    );

    // Cardinal labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final (label, angle) in [('N', -math.pi / 2), ('S', math.pi / 2), ('W', math.pi), ('E', 0.0)]) {
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600),
      );
      textPainter.layout();
      final labelRadius = radius - 12;
      final dx = center.dx + labelRadius * math.cos(angle) - textPainter.width / 2;
      final dy = center.dy + labelRadius * math.sin(angle) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(dx, dy));
    }

    // Heading needle
    final needleAngle = (heading - 90) * math.pi / 180;
    final needleEnd = Offset(
      center.dx + (radius - 20) * math.cos(needleAngle),
      center.dy + (radius - 20) * math.sin(needleAngle),
    );
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = AppColors.brandBlue
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Center dot
    canvas.drawCircle(
      center,
      5,
      Paint()..color = AppColors.brandBlue,
    );

    // Glow
    canvas.drawCircle(
      center,
      8,
      Paint()
        ..color = AppColors.brandBlue.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) => oldDelegate.heading != heading;
}
