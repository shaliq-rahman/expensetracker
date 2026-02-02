import 'package:flutter/material.dart';
import 'dart:math';

class StorageChartPainter extends CustomPainter {
  final double videoValue;
  final double imageValue;
  final double docValue;
  final Color videoColor;
  final Color imageColor;
  final Color docColor;
  final Color backgroundColor;

  StorageChartPainter({
    required this.videoValue,
    required this.imageValue,
    required this.docValue,
    required this.videoColor,
    required this.imageColor,
    required this.docColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final strokeWidth = 10.0;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    final startAngle = -pi / 2; // Start from top

    // Draw Video Arc
    final videoPaint = Paint()
      ..color = videoColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    
    final videoSweep = 2 * pi * videoValue;
    canvas.drawArc(rect, startAngle, videoSweep, false, videoPaint);

    // Draw Image Arc
    final imagePaint = Paint()
      ..color = imageColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final imageSweep = 2 * pi * imageValue;
    // Start where video ended
    canvas.drawArc(rect, startAngle + videoSweep, imageSweep, false, imagePaint);

    // Draw Doc Arc
    final docPaint = Paint()
      ..color = docColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final docSweep = 2 * pi * docValue;
    // Start where image ended
    canvas.drawArc(rect, startAngle + videoSweep + imageSweep, docSweep, false, docPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
