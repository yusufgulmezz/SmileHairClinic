import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 5 adımlı dairesel ilerleme göstergesi
class StepCircularProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final double size;

  const StepCircularProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Arka plan dairesi
          CustomPaint(
            size: Size(size, size),
            painter: _StepProgressPainter(
              currentStep: currentStep,
              totalSteps: totalSteps,
              completedColor: Colors.green,
              remainingColor: Colors.grey.shade300,
            ),
          ),
          // Ortadaki sayı
          Center(
            child: Text(
              '$currentStep/$totalSteps',
              style: TextStyle(
                fontSize: size * 0.2,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepProgressPainter extends CustomPainter {
  final int currentStep;
  final int totalSteps;
  final Color completedColor;
  final Color remainingColor;

  _StepProgressPainter({
    required this.currentStep,
    required this.totalSteps,
    required this.completedColor,
    required this.remainingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    final strokeWidth = 8.0;

    // Her adım için segment açısı
    final segmentAngle = (2 * math.pi) / totalSteps;
    final startAngle = -math.pi / 2; // Üstten başla

    for (int i = 0; i < totalSteps; i++) {
      final angle = startAngle + (i * segmentAngle);
      final isCompleted = i < currentStep;

      final paint = Paint()
        ..color = isCompleted ? completedColor : remainingColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        segmentAngle - 0.1, // Segmentler arası boşluk
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StepProgressPainter oldDelegate) {
    return oldDelegate.currentStep != currentStep;
  }
}

