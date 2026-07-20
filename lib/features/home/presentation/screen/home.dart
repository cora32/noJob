import 'dart:math';

import 'package:NoJob/features/home/presentation/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@Preview(name: 'Preview test')
Widget p() => ChartWidget();

class ChartWidget extends ConsumerWidget {
  const ChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);

    final chartWidget = state.when(
      data: (state) {
        final totalCount = state.arcDataList.isNotEmpty ? state.arcDataList
            .first.total : 0;
        final offerCount = state.arcDataList
            .firstWhere((e) => e.type == ApplicationType.offer,
            orElse: () => ArcData.empty())
            .count;

        return SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: ArcPainter(items: state.arcDataList),
            child: Center(
              child: InfoPanel(
                total: totalCount,
                offers: offerCount,
              ),
            ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: chartWidget,
          ),
        ),
      ),
    );
  }
}

class InfoPanel extends StatelessWidget {
  final int total;
  final int offers;

  const InfoPanel({super.key, required this.total, required this.offers});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 14),
            children: [
              TextSpan(
                text: '$total',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: '\ntotal'),
            ],
          ),
        ),
        const SizedBox(width: 24),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(color: Colors.red, fontSize: 14),
            children: [
              TextSpan(
                text: '$offers',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: '\noffers'),
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
  late List<InnerData> innerData = [];

  static const double strokeWidth = 22.0;

  ArcPainter({required this.items}) {
    innerData = [];

    var lastStartAngle = -90.0;

    for (var item in items) {
      final paint = Paint()
        ..color = item.type.color
        ..style = PaintingStyle.stroke
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

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height,
    );

    for (var item in innerData.reversed) {
      canvas.drawArc(
        rect,
        item.startAngle.toRad(),
        item.sweepAngle.toRad(),
        false,
        item.paint,
      );
    }
  }

  double calcSweepAngle({required int count, required int total}) =>
      count / total.toDouble() * 360.0;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as ArcPainter).items != items;
  }
}

extension RadExt on double {
  double toRad() => this * (pi / 180);
}
