import 'package:NoJob/features/home/presentation/screen/chart_widget.dart';
import 'package:NoJob/features/home/presentation/screen/pie_chart.dart';
import 'package:NoJob/features/logs/presentation/full_log_screen.dart';
import 'package:NoJob/features/logs/presentation/log_widget2.dart';
import 'package:NoJob/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:NoJob/features/title/ui/AppTitle.dart';
import 'package:NoJob/features/title/ui/AppTitleProvider.dart';
import 'package:NoJob/features/url_input/presentation/UrlFieldWidget.dart';
import 'package:NoJob/l10n/app_localizations.dart';
import 'package:NoJob/shared/extensions.dart';
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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(appTitleProvider);

    return themeState.when(
      data: (state) {
        final colors = state.selectedTheme.colorTheme;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateTitle: (context) => context.res.appName,
          theme: ThemeData(
            brightness: colors.isDark ? Brightness.dark : Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: colors.accentColor,
              primary: colors.accentColor,
              surface: colors.isDark ? Colors.grey[900] : Colors.white,
              brightness: colors.isDark ? Brightness.dark : Brightness.light,
            ),
            scaffoldBackgroundColor: colors.backgroundColor,
            cardTheme: CardThemeData(
              color: colors.isDark ? Colors.grey[900] : Colors.white,
              elevation: 4,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: colors.isDark ? Colors.grey[900] : Colors.white,
            ),
            extensions: [
              NoJobThemeExtension(
                colorTheme: ColorTheme(
                  backgroundColor: colors.backgroundColor,
                  accentColor: colors.accentColor,
                  isDark: colors.isDark,
                ),
              ),
            ],
          ),
          home: const ScaffoldWidget(),
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (err, stack) => MaterialApp(
        home: Scaffold(body: Center(child: Text(err.toString()))),
      ),
    );
  }
}

class ScaffoldWidget extends ConsumerWidget {
  const ScaffoldWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentScreen = ref.watch(navigationProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: AppTitle(),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOut)),
              ),
              child: child,
            ),
          );
        },
        child: switch (currentScreen) {
          AppScreen.dashboard =>
          const DashboardScreen(key: ValueKey('dashboard')),
          AppScreen.fullLog => const FullLogScreen(key: ValueKey('fullLog')),
        },
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        verticalDirection: VerticalDirection.up,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 64),
          const LogWidget2(),
          const SizedBox(height: 8),
          const UrlFieldWidget(),
          const SizedBox(height: 32),
          SizedBox(
            height: 350,
            child: Row(
              textDirection: TextDirection.rtl,
              verticalDirection: VerticalDirection.down,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const LineChartWidget(),
                const SizedBox(width: 32),
                const PieWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
