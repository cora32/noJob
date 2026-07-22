import 'package:NoJob/features/home/presentation/providers/home_provider.dart';
import 'package:NoJob/shared/extensions.dart';
import 'package:flutter/material.dart';

class _InnerData {
  final Paint paint;
  final double startAngle;
  final double sweepAngle;

  _InnerData({
    required this.paint,
    required this.startAngle,
    required this.sweepAngle,
  });
}

class ArcPainter extends CustomPainter {
  final List<ArcData> items;
  final int? hoveredIndex;
  final Offset? hoveredCenter;
  final double extensionFactor;
  late List<_InnerData> _innerData = [];
  final cardPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  final bgPaint = Paint()
    ..color = const Color(0xFFF2F2F2)
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round;

  static const double strokeWidth = 22.0;

  ArcPainter({
    required this.items,
    this.hoveredCenter,
    this.hoveredIndex,
    this.extensionFactor = 0.0,
  }) {
    _innerData = [];

    var lastStartAngle = -90.0;

    for (var item in items) {
      final paint = Paint()
        ..color = item.type.color
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = calcSweepAngle(count: item.count, total: item.total);

      _innerData.add(
        _InnerData(
          paint: paint,
          startAngle: lastStartAngle,
          sweepAngle: sweepAngle,
        ),
      );

      lastStartAngle += sweepAngle;
    }
  }

  void _drawGlowingSegment(Canvas canvas, Rect rect) {
    // Draw hovered item with glow
    if (hoveredIndex != null && hoveredIndex! < _innerData.length) {
      final item = _innerData[hoveredIndex!];

      // Glow layer
      final glowPaint = Paint()
        ..color = item.paint.color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawArc(
        rect,
        item.startAngle.toRad(),
        item.sweepAngle.toRad(),
        false,
        glowPaint,
      );

      // Main segment
      canvas.drawArc(
        rect,
        item.startAngle.toRad(),
        item.sweepAngle.toRad(),
        false,
        item.paint,
      );

      _drawVolume(canvas, rect, item.startAngle, item.sweepAngle);
    }
  }

  void _drawVolume(
    Canvas canvas,
    Rect rect,
    double startAngle,
    double sweepAngle,
  ) {
    // 1. Inner Shadow (bottom-right offset)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final shadowRect = rect.shift(const Offset(1.5, 1.5));
    canvas.drawArc(
      shadowRect,
      startAngle.toRad(),
      sweepAngle.toRad(),
      false,
      shadowPaint,
    );

    // 2. Inner Highlight (top-left offset)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final highlightRect = rect.shift(const Offset(-1.5, -1.5));
    canvas.drawArc(
      highlightRect,
      startAngle.toRad(),
      sweepAngle.toRad(),
      false,
      highlightPaint,
    );
  }

  void _drawLineAndLabel(
    Canvas canvas,
    Offset? hoveredCenter,
    int? hoveredIndex,
    Size size,
  ) {
    if (hoveredCenter != null && hoveredIndex != null && extensionFactor > 0) {
      final centerPoint = Offset(size.width / 2, size.height / 2);
      final direction = hoveredCenter - centerPoint;
      final normal = direction / direction.distance;
      final extendedPoint = hoveredCenter + normal * 60 * extensionFactor;
      final extendedPointForLabel =
          hoveredCenter + normal * 80 * extensionFactor;
      final color = items[hoveredIndex].type.color.withValues(alpha: 0.8);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(hoveredCenter, extendedPoint, paint);

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawCircle(extendedPoint, 4, dotPaint);

      // Render Label
      final valueTextSpan = TextSpan(
        text: '${items[hoveredIndex].count}',
        style: TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      final labelTextSpan = TextSpan(
        text: items[hoveredIndex].type.nameCode,
        style: TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      );
      final valueTextPainter = TextPainter(
        text: valueTextSpan,
        textDirection: TextDirection.ltr,
      );
      final labelTextPainter = TextPainter(
        text: labelTextSpan,
        textDirection: TextDirection.ltr,
      );
      valueTextPainter.layout();
      labelTextPainter.layout();

      // Card dimensions and padding
      const horizontalPadding = 8.0;
      const verticalPadding = 4.0;
      const borderRadius = 4.0;

      final cardWidth =
          labelTextPainter.width +
          valueTextPainter.width +
          horizontalPadding * 2;
      final cardHeight =
          labelTextPainter.height +
          valueTextPainter.height +
          verticalPadding * 2;

      // Position the Card centered at extendedPointForLabel
      final cardRect = Rect.fromCenter(
        center: extendedPointForLabel,
        width: cardWidth,
        height: cardHeight,
      );
      final cardRRect = RRect.fromRectAndRadius(
        cardRect,
        const Radius.circular(borderRadius),
      );

      // Draw Shadow
      final shadowPath = Path()..addRRect(cardRRect);
      canvas.drawShadow(
        shadowPath,
        Colors.black.withValues(alpha: extensionFactor),
        4.0,
        true,
      );

      // Draw Card Background
      canvas.drawRRect(cardRRect, cardPaint);

      // Position text centered within the card
      final labelTextOffset = Offset(
        extendedPointForLabel.dx - labelTextPainter.width / 2,
        extendedPointForLabel.dy - labelTextPainter.height,
      );
      labelTextPainter.paint(canvas, labelTextOffset);

      final valueTextOffset = Offset(
        extendedPointForLabel.dx - valueTextPainter.width / 2,
        extendedPointForLabel.dy,
      );
      valueTextPainter.paint(canvas, valueTextOffset);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height,
    );

    // Draw bg-arc
    canvas.drawArc(rect, -90.0.toRad(), 360.0.toRad(), false, bgPaint);
    _drawVolume(canvas, rect, -90.0, 360.0);

    // Draw non-hovered items first
    for (int i = _innerData.length - 1; i >= 0; i--) {
      if (i == hoveredIndex) {
        _drawGlowingSegment(canvas, rect);
      } else {
        canvas.drawArc(
          rect,
          _innerData[i].startAngle.toRad(),
          _innerData[i].sweepAngle.toRad(),
          false,
          _innerData[i].paint,
        );
        _drawVolume(
          canvas,
          rect,
          _innerData[i].startAngle,
          _innerData[i].sweepAngle,
        );
      }
    }

    // Draw popup line
    if (hoveredCenter != null) {
      _drawLineAndLabel(canvas, hoveredCenter, hoveredIndex, size);
    }
  }

  double calcSweepAngle({required int count, required int total}) =>
      count / total.toDouble() * 360.0;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    final old = oldDelegate as ArcPainter;
    return old.items != items ||
        old.hoveredIndex != hoveredIndex ||
        old.hoveredCenter != hoveredCenter ||
        old.extensionFactor != extensionFactor;
  }
}
