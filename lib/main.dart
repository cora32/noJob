import 'package:NoJob/features/home/presentation/screen/chart_widget.dart';
import 'package:NoJob/features/home/presentation/screen/pie_chart.dart';
import 'package:NoJob/features/logs/presentation/log_screen.dart';
import 'package:NoJob/features/title/ui/AppTitle.dart';
import 'package:NoJob/l10n/app_localizations.dart';
import 'package:NoJob/shared/persistence/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(StorageService(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.red)),
      home: const ScaffoldWidget(),
    );
  }
}

class ScaffoldWidget extends StatelessWidget {
  const ScaffoldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
            child: const AppTitle()),
      ),
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
                textDirection: TextDirection.rtl,
                verticalDirection: VerticalDirection.down,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LogWidget(),
                  const SizedBox(width: 32),
                  const PieWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}