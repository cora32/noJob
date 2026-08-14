import 'dart:math';

import 'package:NoJob/features/home/presentation/providers/home_provider.dart';
import 'package:NoJob/features/home/presentation/providers/line_chart_provider.dart';
import 'package:NoJob/shared/extensions.dart';
import 'package:NoJob/shared/shared.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LineChartWidget extends ConsumerWidget {
  const LineChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lineChartProvider);

    return state.when(
      data: (state) => LineChartCard(
        applicationsToday: state.applicationsToday,
        sourceData: state.sourceData,
      ),
      error: (error, stack) {
        return Text(error.toString());
      },
      loading: () => const CircularProgressIndicator(),
    );
  }
}

class LineChartCard extends StatelessWidget {
  final Map<SupportedSite, List<FlSpot>> sourceData;
  final int applicationsToday;

  const LineChartCard({
    super.key,
    required this.sourceData,
    required this.applicationsToday,
  });

  @override
  Widget build(BuildContext context) {
    final firstSpots = sourceData.values.firstWhere(
      (spots) => spots.isNotEmpty,
      orElse: () => [],
    );

    final baseDate = DateTime.now().subtract(
      Duration(days: firstSpots.isNotEmpty ? firstSpots.length - 1 : 13),
    );

    double maxVal = 0;
    for (var spots in sourceData.values) {
      if (spots.isNotEmpty) {
        final currentMax = spots.map((s) => s.y).reduce(max);
        if (currentMax > maxVal) maxVal = currentMax;
      }
    }

    final double computedMaxY = max(6.0, maxVal + 1);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.res.appsToday(applicationsToday),
              style: labelStyle,
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: EdgeInsets.only(right: 32),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 500,
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) =>
                          context.theme.cardColor,
                          tooltipBorder: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                spot.y.toInt().toString(),
                                TextStyle(
                                  color: spot.bar.color ?? Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Color(0xffe7e7e7),
                            strokeWidth: 0.5,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return const FlLine(
                            color: Color(0xffe7e7e7),
                            strokeWidth: 0.5,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final date = baseDate.add(
                                Duration(days: value.toInt()),
                              );

                              return SideTitleWidget(
                                meta: meta,
                                space: 4,
                                child: Text(
                                  DateFormat('dd/MM').format(date),
                                  style: const TextStyle(
                                    color: Color(0xff68737d),
                                    fontSize: 8,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                meta: meta,
                                space: 8,
                                child: Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Color(0xff68737d),
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: const Color(0xff37434d)),
                      ),
                      minX: 0,
                      maxX: (firstSpots.length - 1).toDouble(),
                      minY: 0,
                      maxY: computedMaxY,
                      lineBarsData: sourceData.entries.map((entry) {
                        final source = entry.key;
                        final spots = entry.value;
                        return LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          preventCurveOverShooting: true,
                          color: source.color,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: source.color.withValues(alpha: 0.1),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 32),
              child: LegendWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

class LegendWidget extends StatelessWidget {
  const LegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: SupportedSite.values
          .where((s) => s != SupportedSite.none)
          .map((source) => _LegendItem(source: source))
          .toList(),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final SupportedSite source;

  const _LegendItem({required this.source});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: source.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          source.nameCode.toUpperCase(),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
