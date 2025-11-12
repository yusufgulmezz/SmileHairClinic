import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Circle dışında 5 parçalı ilerleme göstergesi (saat yönünde)
class CircularProgressRing extends StatelessWidget {
  final int completedSteps;
  final int totalSteps;
  final double circleRadius;
  final double strokeWidth;
  final Color completedColor;
  final Color remainingColor;

  const CircularProgressRing({
    super.key,
    required this.completedSteps,
    this.totalSteps = 5,
    this.circleRadius = 150,
    this.strokeWidth = 10.0,
    this.completedColor = Colors.green,
    this.remainingColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(
        (circleRadius + strokeWidth) * 2,
        (circleRadius + strokeWidth) * 2,
      ),
      painter: _CircularProgressRingPainter(
        completedSteps: completedSteps,
        totalSteps: totalSteps,
        circleRadius: circleRadius,
        strokeWidth: strokeWidth,
        completedColor: completedColor,
        remainingColor: remainingColor,
      ),
    );
  }
}

class _CircularProgressRingPainter extends CustomPainter {
  final int completedSteps;
  final int totalSteps;
  final double circleRadius;
  final double strokeWidth;
  final Color completedColor;
  final Color remainingColor;

  _CircularProgressRingPainter({
    required this.completedSteps,
    required this.totalSteps,
    required this.circleRadius,
    required this.strokeWidth,
    required this.completedColor,
    required this.remainingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = circleRadius + strokeWidth / 2;

    // Her adım için segment açısı (360 derece / 5 = 72 derece)
    final segmentAngle = (2 * math.pi) / totalSteps;
    
    // Saat yönünde başlamak için -90 derece (üstten başla)
    final startAngle = -math.pi / 2;

    for (int i = 0; i < totalSteps; i++) {
      final angle = startAngle + (i * segmentAngle);
      final isCompleted = i < completedSteps;

      final paint = Paint()
        ..color = isCompleted ? completedColor : remainingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Her segment'i çiz (segmentAngle - 0.1 radyan boşluk bırak)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        angle,
        segmentAngle - 0.15, // Segmentler arası küçük boşluk
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularProgressRingPainter oldDelegate) {
    return oldDelegate.completedSteps != completedSteps ||
        oldDelegate.totalSteps != totalSteps ||
        oldDelegate.circleRadius != circleRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

