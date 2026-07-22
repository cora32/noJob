import 'dart:math';

import 'package:NoJob/features/home/presentation/providers/home_provider.dart';
import 'package:NoJob/features/home/presentation/screen/arc_painter.dart';
import 'package:NoJob/features/home/presentation/screen/info_panel.dart';
import 'package:NoJob/shared/extensions.dart';
import 'package:NoJob/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@Preview(name: 'Preview test')
Widget p() => PieWidget();

class PieWidget extends ConsumerStatefulWidget {
  const PieWidget({super.key});

  @override
  ConsumerState<PieWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends ConsumerState<PieWidget>
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
      child: Card(
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: Colors.white,

        child: Padding(
          padding: const EdgeInsets.only(
            top: 16,
            bottom: 4,
            left: 32,
            right: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overview', style: labelStyle),
              Padding(padding: const EdgeInsets.all(32), child: chartWidget),
            ],
          ),
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
