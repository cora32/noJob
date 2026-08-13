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
    with TickerProviderStateMixin {
  int? _hoveredIndex;
  Offset? _hoveredCenter;

  List<ArcData> _previousData = [];
  List<ArcData> _currentData = [];

  late AnimationController _controller;
  late Animation<double> _animation;

  late AnimationController _drawController;
  late Animation<double> _drawAnimation;

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

    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _drawAnimation = CurvedAnimation(
      parent: _drawController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _drawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(homeProvider, (previous, next) {
      if (next is AsyncData && next.value != null && mounted) {
        setState(() {
          if (_currentData.isNotEmpty) {
            _previousData = _currentData;
          }
          _currentData = next.value!.arcDataList;
        });
        _drawController.forward(from: 0.0);
      }
    });

    final state = ref.watch(homeProvider);

    final chartWidget = state.when(
      data: (homeState) {
        if (_currentData.isEmpty && homeState.arcDataList.isNotEmpty) {
          _currentData = homeState.arcDataList;
          _drawController.forward(from: 0.0);
        }

        final totalCount =
        homeState.arcDataList.isNotEmpty ? homeState.arcDataList.first.total
            .toInt() : 0;
        final rejectionsCount = homeState.arcDataList
            .firstWhere(
              (e) => e.type == ApplicationType.rejected,
              orElse: () => ArcData.empty(),
            )
            .count
            .toInt();
        final rejectedDetailedCount = homeState.arcDataList
            .firstWhere(
              (e) => e.type == ApplicationType.rejectedDetailed,
              orElse: () => ArcData.empty(),
            )
            .count
            .toInt();
        final offerCount = homeState.arcDataList
            .firstWhere(
              (e) => e.type == ApplicationType.offer,
              orElse: () => ArcData.empty(),
            )
            .count
            .toInt();

        return MouseRegion(
          onHover: (event) {
            final (index, center) = _hitTest(
              event.localPosition,
              homeState.arcDataList,
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
            animation: Listenable.merge([_animation, _drawAnimation]),
            builder: (context, child) {
              final animatedData = _interpolateData(_drawAnimation.value);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CustomPaint(
                      painter: ArcPainter(
                        getLocalizedName: (type) => type.localizedName(context),
                        items: animatedData,
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
        child: Padding(
          padding: const EdgeInsets.only(
            top: 16,
            bottom: 4,
            left: 16,
            right: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.res.overview, style: labelStyle),
              Padding(padding: const EdgeInsets.all(32), child: chartWidget),
            ],
          ),
        ),
      ),
    );
  }

  List<ArcData> _interpolateData(double t) {
    if (_previousData.isEmpty) {
      // If no previous data, interpolate from 0 count
      return _currentData.map((d) {
        return ArcData(
          total: d.total,
          count: d.count * t,
          type: d.type,
        );
      }).toList();
    }

    final result = <ArcData>[];
    final allTypes = {
      ..._previousData.map((d) => d.type),
      ..._currentData.map((d) => d.type),
    };

    // We want to maintain a consistent order for the chart segments
    // Let's use the ApplicationType.values order
    for (final type in ApplicationType.values) {
      if (!allTypes.contains(type)) continue;

      final prev = _previousData.firstWhere(
            (d) => d.type == type,
        orElse: () => ArcData(total: 1.0, count: 0.0, type: type),
      );
      final curr = _currentData.firstWhere(
            (d) => d.type == type,
        orElse: () => ArcData(total: 1.0, count: 0.0, type: type),
      );

      final interpolatedCount = prev.count + (curr.count - prev.count) * t;
      final interpolatedTotal = prev.total + (curr.total - prev.total) * t;

      result.add(ArcData(
        total: interpolatedTotal,
        count: interpolatedCount,
        type: type,
      ));
    }

    return result;
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
