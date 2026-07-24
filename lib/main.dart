import 'package:NoJob/features/home/presentation/screen/chart_widget.dart';
import 'package:NoJob/features/home/presentation/screen/pie_chart.dart';
import 'package:NoJob/features/logs/presentation/log_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'noJob',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ScaffoldWidget(),
    );
  }
}

class ScaffoldWidget extends StatelessWidget {
  const ScaffoldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: Column(
            verticalDirection: VerticalDirection.up,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64),
              const LineChartWidget(),
              const SizedBox(height: 32),
              SizedBox(
                height: 350,
                child: Row(
                  verticalDirection: VerticalDirection.down,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PieWidget(),
                    const SizedBox(width: 32),
                    const LogWidget(),
                  ],
                ),
              ),
            ],
          ),
        )
    );
  }
}