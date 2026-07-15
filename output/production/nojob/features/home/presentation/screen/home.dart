import 'dart:math';

import 'package:NoJob/features/home/presentation/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@Preview(name: 'Preview tezt2')
Widget p2() => Text("test");

@Preview(name: 'Preview test')
Widget p() => ChartWidget();

class ChartWidget extends ConsumerWidget {
  const ChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);

    return Center(
      child: CustomPaint(
        painter: ArcPainter(data: state.arcData),
      ),
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

  ArcPainter({required this.data})
    : totalPaint = Paint()
        ..color = data.total.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
      initialInterviewsPaint = Paint()
        ..color = data.initialInterviews.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.square,
      techInterviewsPaint = Paint()
        ..color = data.initialInterviews.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
      rejectedPaint = Paint()
        ..color = data.initialInterviews.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
      rejectedWithFeedbackPaint = Paint()
        ..color = data.initialInterviews.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
      offersPaint = Paint()
        ..color = data.initialInterviews.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height,
    );

    // Draw totals
    final totalStartAngle = -pi / 2.0;
    final totalSweepAngle = 360.0;

    canvas.drawArc(rect, totalStartAngle, totalSweepAngle, false, totalPaint);

    // Draw initial interviews
    final initialsStartAngle = totalStartAngle;
    final initialsSweepAngle = calcSweepAngle(
      count: data.initialInterviews.count,
      total: data.total.count,
    );

    canvas.drawArc(
      rect,
      initialsStartAngle,
      initialsSweepAngle,
      false,
      initialInterviewsPaint,
    );

    // Draw tech interviews
    final techStartAngle = totalStartAngle + initialsSweepAngle;
    final techSweepAngle = calcSweepAngle(
      count: data.initialInterviews.count,
      total: data.total.count,
    );

    canvas.drawArc(
      rect,
      techStartAngle,
      techSweepAngle,
      false,
      initialInterviewsPaint,
    );

    // Draw rejected
    final rejectedStartAngle =
        totalStartAngle + initialsSweepAngle + techSweepAngle;
    final rejectedSweepAngle = calcSweepAngle(
      count: data.initialInterviews.count,
      total: data.total.count,
    );

    canvas.drawArc(
      rect,
      rejectedStartAngle,
      rejectedSweepAngle,
      false,
      rejectedPaint,
    );

    // Draw rejected with feedback
    final rejectedWithFeedbackStartAngle =
        totalStartAngle +
        initialsSweepAngle +
        techSweepAngle +
        rejectedSweepAngle;
    final rejectedWithFeedbackSweepAngle = calcSweepAngle(
      count: data.initialInterviews.count,
      total: data.total.count,
    );

    canvas.drawArc(
      rect,
      rejectedWithFeedbackStartAngle,
      rejectedWithFeedbackSweepAngle,
      false,
      rejectedWithFeedbackPaint,
    );

    // Draw offers
    final offersStartAngle =
        totalStartAngle +
        initialsSweepAngle +
        techSweepAngle +
        rejectedSweepAngle +
        rejectedWithFeedbackSweepAngle;
    final offersSweepAngle = calcSweepAngle(
      count: data.initialInterviews.count,
      total: data.total.count,
    );

    canvas.drawArc(
      rect,
      rejectedSweepAngle,
      offersSweepAngle,
      false,
      offersPaint,
    );
  }

  double calcSweepAngle({required int count, required int total}) =>
      count / total * 360.0;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as ArcPainter).data != data;
  }
}
