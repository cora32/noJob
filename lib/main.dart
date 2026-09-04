import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/home/presentation/ui/home_screen.dart';
import 'package:nojob/features/logs/presentation/ui/full_log_screen.dart';
import 'package:nojob/features/navigation/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:nojob/features/title/ui/AppTitle.dart';
import 'package:nojob/features/title/ui/AppTitleProvider.dart';
import 'package:nojob/l10n/app_localizations.dart';
import 'package:nojob/shared/extensions.dart';
import 'package:nojob/shared/persistence/storage_service.dart';
import 'package:nojob/shared/providers.dart';
import 'package:nojob/shared/server/server.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fullscreen + transparent navbar
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

  // DB init: Use FFI for desktop, native for mobile
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  final dbPath = join(await getDatabasesPath(), 'nojob.db');

  // PeerNet init
  startPeerNet(dbPath);

  // Discover peer nodes
  startPeerNodesDiscovery();

  // SharedPrefs init
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
    final currentScreen = ref.watch(navigationViewModel);

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
          ref.read(navigationViewModel.notifier).goBack();
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
