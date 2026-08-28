import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/home/data/database_service.dart';
import 'package:nojob/features/home/presentation/screen/chart_widget.dart';
import 'package:nojob/features/home/presentation/screen/pie_chart.dart';
import 'package:nojob/features/logs/presentation/full_log_screen.dart';
import 'package:nojob/features/logs/presentation/log_widget2.dart';
import 'package:nojob/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:nojob/features/title/ui/AppTitle.dart';
import 'package:nojob/features/title/ui/AppTitleProvider.dart';
import 'package:nojob/features/url_input/presentation/UrlFieldWidget.dart';
import 'package:nojob/l10n/app_localizations.dart';
import 'package:nojob/shared/extensions.dart';
import 'package:nojob/shared/persistence/storage_service.dart';
import 'package:path/path.dart';
import 'package:peernet/server/peernet_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> pnEntryPoint(Map<String, dynamic> config) async {
  // final String dbPath = config['dbPath'];

  final container = ProviderContainer();
  final dbService = container.read(dbProvider);
  final db = await dbService.database;

  final peerNet = getPeerNet()
    ..onGetSyncData = (data) async {
      final results = await db.query('jobs');
      return "DB Items: ${results.length}";
    };

  await peerNet.start(7834);
}

void startPeerNet(String dbPath) {
  final rcvPort = ReceivePort();

  try {
    Isolate.spawn(pnEntryPoint, {
      'sendPort': rcvPort.sendPort,
      'dbPath': dbPath,
    });
  } catch (e) {
    "PeerNet: Failed to start server: $e".e;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final prefs = await SharedPreferences.getInstance();

  final dbPath = join(await getDatabasesPath(), 'nojob.db');
  startPeerNet(dbPath);

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
          home: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: colors.isDark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: colors.isDark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarContrastEnforced: false,
            ),
            child: const ScaffoldWidget(),
          ),
        );
      },
      loading: () => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.transparent,
            statusBarColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
          ),
          child: Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      ),
      error: (err, stack) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.transparent,
            statusBarColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
          ),
          child: Scaffold(body: Center(child: Text(err.toString()))),
        ),
      ),
    );
  }
}

class ScaffoldWidget extends ConsumerWidget {
  const ScaffoldWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentScreen = ref.watch(navigationProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final NavigatorState? navigator = Navigator.maybeOf(context);
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
          return;
        }

        if (currentScreen == AppScreen.fullLog) {
          ref.read(navigationProvider.notifier).goBack();
        }
      },
      child: Scaffold(
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
            AppScreen.dashboard => const DashboardScreen(
              key: ValueKey('dashboard'),
            ),
            AppScreen.fullLog => const FullLogScreen(key: ValueKey('fullLog')),
          },
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          verticalDirection: VerticalDirection.up,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(height: 64),
            const LogWidget2(),
            const SizedBox(height: 8),
            const UrlFieldWidget(),
            const SizedBox(height: 32),
            SizedBox(
              child: Wrap(
                textDirection: TextDirection.rtl,
                verticalDirection: VerticalDirection.down,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16.0,
                runSpacing: 16.0,
                children: [const LineChartWidget(), const PieWidget()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
