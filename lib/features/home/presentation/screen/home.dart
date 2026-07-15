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
        return CustomPaint(
          size: Size(200, 200),
          painter: ArcPainter(data: state.arcData),
        );
      },
      error: (error, stack) {
        return Text(error.toString());
      },
      loading: () => const CircularProgressIndicator(),
    );

    return Container(
      color: Colors.black,
      child: Center(child: chartWidget),
    );
  }
}

class ArcPainter extends CustomPainter {
  final ArcData data;

  final Paint totalPaint;
  final Paint initialInterviewsPaint;
  final Paint techInterviewsPaint;
  final Paint rejectedPaint;
  final Paint rejectedWithFeedbackPaint;
  final Paint offersPaint;

  static const double strokeWidth = 22.0;

  ArcPainter({required this.data})
    : totalPaint = Paint()
        ..color = data.total.status.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
      initialInterviewsPaint = Paint()
        ..color = data.initialInterviews.status.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
      techInterviewsPaint = Paint()
        ..color = data.technicalInterviews.status.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
      rejectedPaint = Paint()
        ..color = data.rejected.status.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
      rejectedWithFeedbackPaint = Paint()
        ..color = data.rejectedWithFeedback.status.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
      offersPaint = Paint()
        ..color = data.offers.status.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height,
    );

    final startAngle = -90.0;

    // Draw pending
    canvas.drawArc(rect, startAngle.toRad(), 360.0.toRad(), false, totalPaint);

    // Calc initial interviews
    final initialsStartAngle = startAngle;
    final initialsSweepAngle = calcSweepAngle(
      count: data.initialInterviews.count,
      total: data.total.count,
    );

    // Calc tech interviews
    final techStartAngle = initialsStartAngle + initialsSweepAngle;
    final techSweepAngle = calcSweepAngle(
      count: data.technicalInterviews.count,
      total: data.total.count,
    );

    // Calc rejected
    final rejectedStartAngle = techStartAngle + techSweepAngle;
    final rejectedSweepAngle = calcSweepAngle(
      count: data.rejected.count,
      total: data.total.count,
    );

    // Calc rejected with feedback
    final rejectedWithFeedbackStartAngle =
        rejectedStartAngle + rejectedSweepAngle;
    final rejectedWithFeedbackSweepAngle = calcSweepAngle(
      count: data.rejectedWithFeedback.count,
      total: data.total.count,
    );

    // Calc offers
    final offersStartAngle =
        rejectedWithFeedbackStartAngle + rejectedWithFeedbackSweepAngle;
    final offersSweepAngle = calcSweepAngle(
      count: data.offers.count,
      total: data.total.count,
    ).toRad();

    // Draw offers
    canvas.drawArc(
      rect,
      offersStartAngle.toRad(),
      offersSweepAngle.toRad(),
      false,
      offersPaint,
    );

    // Draw rejected with feedback
    canvas.drawArc(
      rect,
      rejectedWithFeedbackStartAngle.toRad(),
      rejectedWithFeedbackSweepAngle.toRad(),
      false,
      rejectedWithFeedbackPaint,
    );

    // Draw rejected
    canvas.drawArc(
      rect,
      rejectedStartAngle.toRad(),
      rejectedSweepAngle.toRad(),
      false,
      rejectedPaint,
    );

    // Draw tech interviews
    canvas.drawArc(
      rect,
      techStartAngle.toRad(),
      techSweepAngle.toRad(),
      false,
      techInterviewsPaint,
    );

    // Draw initial interviews
    canvas.drawArc(
      rect,
      initialsStartAngle.toRad(),
      initialsSweepAngle.toRad(),
      false,
      initialInterviewsPaint,
    );

    debugPrint(
      "offersStartAngle: $offersStartAngle, offersSweepAngle: $offersSweepAngle",
    );
    debugPrint("total: ${data.total.count}, offers: ${data.offers.count}");
    debugPrint("color: ${data.offers.status.color}");
  }

  double calcSweepAngle({required int count, required int total}) =>
      count / total.toDouble() * 360.0;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as ArcPainter).data != data;
  }
}

extension RadExt on double {
  double toRad() => this * (pi / 180);
}
