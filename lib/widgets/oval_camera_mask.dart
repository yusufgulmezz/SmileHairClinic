import 'package:flutter/material.dart';

/// Oval içinde kamera görüntüsü, dışında beyaz maske
class OvalCameraMask extends StatelessWidget {
  final Widget cameraPreview;
  final double width;
  final double height;
  final Color backgroundColor;

  const OvalCameraMask({
    super.key,
    required this.cameraPreview,
    this.width = 200,
    this.height = 300,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Beyaz arka plan (tüm ekran)
        Positioned.fill(
          child: Container(
            color: backgroundColor,
          ),
        ),
        // Oval içinde kamera görüntüsü
        Center(
          child: ClipOval(
            child: SizedBox(
              width: width,
              height: height,
              child: cameraPreview,
            ),
          ),
        ),
      ],
    );
  }
}

