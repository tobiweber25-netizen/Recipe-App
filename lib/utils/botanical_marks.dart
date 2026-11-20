import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Minimalist hand-drawn eucalyptus sprig used as a quiet botanical signature mark.
class BotanicalSprig extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const BotanicalSprig({
    super.key,
    this.size = 36,
    required this.color,
    this.strokeWidth = 1.25,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BotanicalSprigPainter(
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _BotanicalSprigPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _BotanicalSprigPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    // Gentle curved stem from bottom-left toward top-right
    final stem = Path()
      ..moveTo(w * 0.24, h * 0.88)
      ..quadraticBezierTo(w * 0.44, h * 0.56, w * 0.72, h * 0.16);
    canvas.drawPath(stem, strokePaint);

    void drawLeaf(Offset base, double angleRad, double length, double width) {
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate(angleRad);

      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(width, -length * 0.45, 0, -length)
        ..quadraticBezierTo(-width, -length * 0.45, 0, 0)
        ..close();

      canvas.drawPath(leaf, fillPaint);
      canvas.drawPath(leaf, strokePaint);
      canvas.restore();
    }

    // Paired eucalyptus leaves along the stem
    drawLeaf(Offset(w * 0.36, h * 0.70), -0.95, h * 0.24, w * 0.11);
    drawLeaf(Offset(w * 0.41, h * 0.64), 0.72, h * 0.24, w * 0.11);

    drawLeaf(Offset(w * 0.48, h * 0.50), -0.82, h * 0.23, w * 0.105);
    drawLeaf(Offset(w * 0.53, h * 0.44), 0.78, h * 0.22, w * 0.105);

    drawLeaf(Offset(w * 0.61, h * 0.30), -0.68, h * 0.19, w * 0.09);
    drawLeaf(Offset(w * 0.65, h * 0.25), 0.85, h * 0.18, w * 0.085);

    // Crown leaf at stem tip
    drawLeaf(Offset(w * 0.72, h * 0.16), 0.46, h * 0.17, w * 0.08);
  }

  @override
  bool shouldRepaint(covariant _BotanicalSprigPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Calm circular progress ring for Cooking Mode's countertop kitchen timer.
class TimerProgressRing extends StatelessWidget {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const TimerProgressRing({
    super.key,
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.size = 56,
    this.strokeWidth = 3.5,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TimerRingPainter(
          progress: progress.clamp(0.0, 1.0),
          trackColor: trackColor,
          progressColor: progressColor,
          strokeWidth: strokeWidth,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _TimerRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final arcPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
