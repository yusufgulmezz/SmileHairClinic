import 'package:flutter/material.dart';

/// Oval overlay widget - yüz çerçevesi için
class OvalOverlay extends StatelessWidget {
  final Color borderColor;
  final double width;
  final double height;

  const OvalOverlay({
    super.key,
    this.borderColor = Colors.red,
    this.width = 200,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: borderColor,
            width: 3.0,
          ),
        ),
      ),
    );
  }
}

