import 'dart:math';

import 'package:NoJob/features/home/presentation/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@Preview(name: 'Preview test')
Widget p() => ChartWidget();

class ChartWidget extends ConsumerStatefulWidget {
  const ChartWidget({super.key});

  @override
  ConsumerState<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends ConsumerState<ChartWidget>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  Offset? _hoveredCenter;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);

    final chartWidget = state.when(
      data: (state) {
        final totalCount = state.arcDataList.isNotEmpty
            ? state.arcDataList.first.total
            : 0;
        final rejectionsCount = state.arcDataList
            .firstWhere(
              (e) => e.type == ApplicationType.rejected,
          orElse: () => ArcData.empty(),
        )
            .count;
        final rejectedDetailedCount = state.arcDataList
            .firstWhere(
              (e) => e.type == ApplicationType.rejectedDetailed,
          orElse: () => ArcData.empty(),
        )
            .count;
        final offerCount = state.arcDataList
            .firstWhere(
              (e) => e.type == ApplicationType.offer,
          orElse: () => ArcData.empty(),
        )
            .count;

        return MouseRegion(
          onHover: (event) {
            final (index, center) = _hitTest(
              event.localPosition,
              state.arcDataList,
            );
            if (index != _hoveredIndex) {
              setState(() {
                _hoveredIndex = index;
                _hoveredCenter = center;
              });
              if (index != null) {
                _controller.forward(from: 0.0);
              } else {
                _controller.reverse();
              }
            }
          },
          onExit: (event) {
            setState(() {
              _hoveredIndex = null;
              _hoveredCenter = null;
            });
            _controller.reverse();
          },
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              Offset? extendedPoint;
              if (_hoveredCenter != null) {
                const centerPoint = Offset(100, 100);
                final direction = _hoveredCenter! - centerPoint;
                final normal = direction / direction.distance;
                extendedPoint =
                    _hoveredCenter! + normal * 60 * _animation.value;
              }

              final item = state.arcDataList[_hoveredIndex ?? 0];

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CustomPaint(
                      painter: ArcPainter(
                        items: state.arcDataList,
                        hoveredCenter: _hoveredCenter,
                        hoveredIndex: _hoveredIndex,
                        extensionFactor: _animation.value,
                      ),
                      child: Center(
                        child: InfoPanel(
                          total: totalCount,
                          rejections: rejectionsCount + rejectedDetailedCount,
                          offers: offerCount,
                        ),
                      ),
                    ),
                  ),
                  if (_hoveredIndex != null &&
                      extendedPoint != null &&
                      _hoveredIndex! < state.arcDataList.length)
                    Label(
                      extendedPoint,
                      item.type.name,
                      item.count.toString(),
                    ),
                ],
              );
            },
          ),
        );
      },
      error: (error, stack) {
        return Text(error.toString());
      },
      loading: () => const CircularProgressIndicator(),
    );

    return Container(
      color: Colors.transparent,
      child: Center(
        child: Card(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          color: Colors.white,
          child: Padding(padding: const EdgeInsets.all(32), child: chartWidget),
        ),
      ),
    );
  }

  (int?, Offset?) _hitTest(Offset localPosition, List<ArcData> items) {
    const double size = 200.0;
    const double center = size / 2;
    const double strokeWidth = 22.0;
    const double innerRadius = center - strokeWidth / 2;
    const double outerRadius = center + strokeWidth / 2;

    final dx = localPosition.dx - center;
    final dy = localPosition.dy - center;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance < innerRadius || distance > outerRadius) {
      return (null, null);
    }

    // atan2 returns angle in radians from -pi to pi. 0 is 3 o'clock.
    double angle = atan2(dy, dx) * 180 / pi;
    // Normalize to match our starting -90.0
    double normalizedAngle = (angle + 90) % 360;
    if (normalizedAngle < 0) normalizedAngle += 360;

    double currentAngle = 0;
    for (int i = 0; i < items.length; i++) {
      final sweepAngle = (items[i].count / items[i].total.toDouble()) * 360.0;
      if (normalizedAngle >= currentAngle &&
          normalizedAngle <= currentAngle + sweepAngle) {
        // Calculate the center point of the arc
        final midAngle = currentAngle + sweepAngle / 2;
        final actualAngleRad = (midAngle - 90).toRad();
        final arcCenterX = center + center * cos(actualAngleRad);
        final arcCenterY = center + center * sin(actualAngleRad);

        return (i, Offset(arcCenterX, arcCenterY));
      }
      currentAngle += sweepAngle;
    }

    return (null, null);
  }
}

class InfoPanel extends StatelessWidget {
  final int total;
  final int rejections;
  final int offers;

  const InfoPanel({
    super.key,
    required this.total,
    required this.rejections,
    required this.offers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            children: [
              TextSpan(
                text: '$rejections',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(
                text: '\nRejections',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 14),
            children: [
              TextSpan(
                text: '$total',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(
                text: '\nTotal',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(color: Colors.green, fontSize: 14),
            children: [
              TextSpan(
                text: '$offers',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(
                text: '\nOffers',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class InnerData {
  final Paint paint;
  final double startAngle;
  final double sweepAngle;

  InnerData({
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
  late List<InnerData> innerData = [];

  static const double strokeWidth = 22.0;

  ArcPainter({
    required this.items,
    this.hoveredCenter,
    this.hoveredIndex,
    this.extensionFactor = 0.0,
  }) {
    innerData = [];

    var lastStartAngle = -90.0;

    for (var item in items) {
      final paint = Paint()
        ..color = item.type.color
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = calcSweepAngle(count: item.count, total: item.total);

      innerData.add(
        InnerData(
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
    if (hoveredIndex != null && hoveredIndex! < innerData.length) {
      final item = innerData[hoveredIndex!];

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
    }
  }

  void _drawLine(Canvas canvas,
      Offset? hoveredCenter,
      int? hoveredIndex,
      Size size,) {
    if (hoveredCenter != null && extensionFactor > 0) {
      final centerPoint = Offset(size.width / 2, size.height / 2);
      final direction = hoveredCenter - centerPoint;
      final normal = direction / direction.distance;
      final extendedPoint = hoveredCenter + normal * 60 * extensionFactor;
      final color = items[hoveredIndex!].type.color.withValues(alpha: 0.8);

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
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height,
    );

    // Draw non-hovered items first
    for (int i = innerData.length - 1; i >= 0; i--) {
      if (i == hoveredIndex) {
        _drawGlowingSegment(canvas, rect);
      } else {
        canvas.drawArc(
          rect,
          innerData[i].startAngle.toRad(),
          innerData[i].sweepAngle.toRad(),
          false,
          innerData[i].paint,
        );
      }
    }

    // Draw popup line
    if (hoveredCenter != null) {
      _drawLine(canvas, hoveredCenter, hoveredIndex, size);
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

extension RadExt on double {
  double toRad() => this * (pi / 180);
}

class Label extends StatelessWidget {
  final Offset extendedPoint;
  final String name;
  final String count;

  const Label(this.extendedPoint, this.name, this.count, {super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: extendedPoint.dx,
      top: extendedPoint.dy,
      child: IgnorePointer(
        child: FractionalTranslation(
          translation: const Offset(-0.5, -1.2),
          child: Card(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            elevation: 4,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  Text(
                    count,
                    style: const TextStyle(color: Colors.black, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
