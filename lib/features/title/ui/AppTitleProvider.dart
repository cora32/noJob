import 'dart:async';

import 'package:NoJob/shared/persistence/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NoJobThemes {
  blackOrange(
    colorTheme: ColorTheme(
      backgroundColor: Colors.black,
      accentColor: Colors.orange,
    ),
  ),
  light(
    colorTheme: ColorTheme(
      backgroundColor: Colors.white,
      accentColor: Colors.green,
    ),
  );

  final ColorTheme colorTheme;

  const NoJobThemes({required this.colorTheme});
}

class ColorTheme {
  final Color backgroundColor;
  final Color accentColor;

  const ColorTheme({required this.backgroundColor, required this.accentColor});
}

class AppTitleState {
  final NoJobThemes selectedTheme;

  AppTitleState({required this.selectedTheme});

  ColorTheme get selectedColorTheme => selectedTheme.colorTheme;

  static AppTitleState defaultState = AppTitleState(
    selectedTheme: NoJobThemes.light,
  );
}

class AppTitleNotifier extends AsyncNotifier<AppTitleState> {
  @override
  FutureOr<AppTitleState> build() {
    final storage = ref.watch(storageServiceProvider);
    final savedIndex = storage.getThemeIndex();

    if (savedIndex != null &&
        savedIndex >= 0 &&
        savedIndex < NoJobThemes.values.length) {
      return AppTitleState(selectedTheme: NoJobThemes.values[savedIndex]);
    }

    return AppTitleState.defaultState;
  }

  Future<void> selectTheme(NoJobThemes theme) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setThemeIndex(theme.index);
    state = AsyncData(AppTitleState(selectedTheme: theme));
  }
}

final appTitleProvider = AsyncNotifierProvider<AppTitleNotifier, AppTitleState>(
  AppTitleNotifier.new,
);
