import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/home/presentation/providers/home_provider.dart';
import 'package:nojob/features/home/presentation/screen/arc_painter.dart';
import 'package:nojob/features/home/presentation/screen/info_panel.dart';
import 'package:nojob/shared/extensions.dart';
import 'package:nojob/shared/ui/panel.dart';

class PieWidget extends ConsumerStatefulWidget {
  final double chartSize;

  const PieWidget({super.key, required this.chartSize});

  @override
  ConsumerState<PieWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends ConsumerState<PieWidget>
    with TickerProviderStateMixin {
  final GlobalKey _chartKey = GlobalKey();
  int? _hoveredIndex;
  Offset? _hoveredCenter;

  List<ArcData> _previousData = [];
  List<ArcData> _currentData = [];
  List<ApplicationType> _allTypes = []; // Pre-calculated union of types

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
        final sortedList = _sortArcData(next.value!.arcDataList);
        setState(() {
          _previousData = _currentData.isNotEmpty
              ? _currentData
              : sortedList
                    .map((d) => ArcData(total: d.total, count: 0, type: d.type))
                    .toList();
          _currentData = sortedList;
          _allTypes = _computeAllTypes(_previousData, _currentData);
        });
        _drawController.forward(from: 0.0);
      }
    });

    final state = ref.watch(homeProvider);

    final chartWidget = state.when(
      data: (homeState) {
        final sortedArcData = _sortArcData(homeState.arcDataList);

        if (_currentData.isEmpty && sortedArcData.isNotEmpty) {
          setState(() {
            _currentData = sortedArcData;
            _allTypes = _computeAllTypes([], _currentData);
          });
          _drawController.forward(from: 0.0);
        }

        final totalCount = sortedArcData.isNotEmpty
            ? sortedArcData.first.total.toInt()
            : 0;
        final rejectionsCount = sortedArcData
            .firstWhere(
              (e) => e.type == ApplicationType.rejected,
              orElse: () => ArcData.empty(),
            )
            .count
            .toInt();
        final rejectedDetailedCount = sortedArcData
            .firstWhere(
              (e) => e.type == ApplicationType.rejectedDetailed,
              orElse: () => ArcData.empty(),
            )
            .count
            .toInt();
        final offerCount = sortedArcData
            .firstWhere(
              (e) => e.type == ApplicationType.offer,
              orElse: () => ArcData.empty(),
            )
            .count
            .toInt();

        return LayoutBuilder(
          builder: (context, constraints) {
            final detectorSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            return MouseRegion(
              onHover: (event) => _updateInteraction(
                event.localPosition,
                sortedArcData,
                detectorSize,
                widget.chartSize,
              ),
              onExit: (event) {
                setState(() {
                  _hoveredIndex = null;
                  _hoveredCenter = null;
                });
                _controller.reverse();
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _updateInteraction(
                  details.localPosition,
                  sortedArcData,
                  detectorSize,
                  widget.chartSize,
                ),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_animation, _drawAnimation]),
                  builder: (context, child) {
                    final animatedData = _interpolateData(_drawAnimation.value);

                    final pie = Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            height: widget.chartSize,
                            width: widget.chartSize,
                            child: CustomPaint(
                              key: _chartKey,
                              painter: ArcPainter(
                                getLocalizedName: (type) =>
                                    type.localizedName(context),
                                items: animatedData,
                                getArcDataById: (index) => sortedArcData[index],
                                hoveredCenter: _hoveredCenter,
                                hoveredIndex: _hoveredIndex,
                                extensionFactor: _animation.value,
                                screenWidth: MediaQuery.sizeOf(context).width,
                                chartGlobalX: _getChartGlobalX(),
                              ),
                              child: Center(
                                child: InfoPanel(
                                  total: totalCount,
                                  rejections:
                                      rejectionsCount + rejectedDetailedCount,
                                  offers: offerCount,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    return context.isMobile
                        ? pie
                        : ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 300),
                            child: pie,
                          );
                  },
                ),
              ),
            );
          },
        );
      },
      error: (error, stack) {
        return Text(error.toString());
      },
      loading: () => const CircularProgressIndicator(),
    );

    return Panel(title: context.res.overview, height: 250, child: chartWidget);
  }

  double _getChartGlobalX() {
    final RenderBox? renderBox =
        _chartKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.localToGlobal(Offset.zero).dx ?? 0.0;
  }

  void _updateInteraction(
    Offset localPosition,
    List<ArcData> items,
    Size detectorSize,
    double chartSize,
  ) {
    final (index, center) = _hitTest(
      localPosition,
      items,
      detectorSize,
      chartSize,
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
  }

  List<ArcData> _sortArcData(List<ArcData> data) {
    // Sort based on the order defined in ApplicationType enum
    final sorted = List<ArcData>.from(data);
    sorted.sort((a, b) => a.type.index.compareTo(b.type.index));
    return sorted;
  }

  List<ApplicationType> _computeAllTypes(
    List<ArcData> prev,
    List<ArcData> curr,
  ) {
    final types = {
      ...prev.map((d) => d.type),
      ...curr.map((d) => d.type),
    }.toList();
    types.sort((a, b) => a.index.compareTo(b.index));
    return types;
  }

  List<ArcData> _interpolateData(double t) {
    if (_previousData.isEmpty) {
      return _currentData.map((d) {
        return ArcData(total: d.total, count: d.count * t, type: d.type);
      }).toList();
    }

    final result = <ArcData>[];

    for (final type in _allTypes) {
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

      result.add(
        ArcData(total: interpolatedTotal, count: interpolatedCount, type: type),
      );
    }

    return result;
  }

  (int?, Offset?) _hitTest(
    Offset localPosition,
    List<ArcData> items,
    Size detectorSize,
    double chartSize,
  ) {
    double radius = chartSize / 2;
    const double strokeWidth = 22.0;
    const double hitTolerance = 20.0; // Added tolerance for easier tapping
    double innerRadius = radius - strokeWidth / 2 - hitTolerance;
    double outerRadius = radius + strokeWidth / 2 + hitTolerance;

    final dx = localPosition.dx - detectorSize.width / 2;
    final dy = localPosition.dy - detectorSize.height / 2;
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
        // Calculate the center point of the arc relative to the 230x230 box
        final midAngle = currentAngle + sweepAngle / 2;
        final actualAngleRad = (midAngle - 90).toRad();
        final arcCenterX = radius + radius * cos(actualAngleRad);
        final arcCenterY = radius + radius * sin(actualAngleRad);

        return (i, Offset(arcCenterX, arcCenterY));
      }
      currentAngle += sweepAngle;
    }

    return (null, null);
  }
}
