import 'package:NoJob/features/home/presentation/providers/line_chart_provider.dart';
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
        chartData: state.data,
      ),
      error: (error, stack) {
        return Text(error.toString());
      },
      loading: () => CircularProgressIndicator(),
    );
  }
}

class LineChartCard extends StatelessWidget {
  final List<FlSpot> chartData;
  final int applicationsToday;

  const LineChartCard({
    super.key,
    required this.chartData,
    required this.applicationsToday,
  });

  @override
  Widget build(BuildContext context) {
    final baseDate = DateTime.now().subtract(
      Duration(days: chartData.length - 1),
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Applications today: $applicationsToday', style: labelStyle),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartData.length * 60.0,
                  // Increased width slightly for date labels
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Color(0xffe7e7e7),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return const FlLine(
                            color: Color(0xffe7e7e7),
                            strokeWidth: 1,
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
                                space: 8,
                                child: Text(
                                  DateFormat('MMM d').format(date),
                                  style: const TextStyle(
                                    color: Color(0xff68737d),
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 42,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: const Color(0xff37434d)),
                      ),
                      minX: 0,
                      maxX: (chartData.length - 1).toDouble(),
                      minY: 0,
                      maxY: 6,
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartData,
                          isCurved: true,
                          color: Colors.blueAccent,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blueAccent.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
