import 'dart:async';

import 'package:NoJob/shared/persistence/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NoJobThemes {
  blackOrange(
    colorTheme: ColorTheme(
      backgroundColor: Color(0xff2e2e2e),
      accentColor: Color(0xffda5322),
      isDark: true,
    ),
  ),
  light(
    colorTheme: ColorTheme(
      backgroundColor: Color(0xffd8d8d8),
      accentColor: Color(0xff34d61d),
      isDark: false,
    ),
  );

  final ColorTheme colorTheme;

  const NoJobThemes({required this.colorTheme});
}

class ColorTheme {
  final Color backgroundColor;
  final Color accentColor;
  final bool isDark;

  const ColorTheme({
    required this.backgroundColor,
    required this.accentColor,
    required this.isDark,
  });

  static ColorTheme lerp(
    ColorTheme oldColorTheme,
    ColorTheme newColorTheme,
    double t,
  ) {
    return ColorTheme(
      backgroundColor: Color.lerp(
        oldColorTheme.backgroundColor,
        newColorTheme.backgroundColor,
        t,
      )!,
      accentColor: Color.lerp(
        oldColorTheme.accentColor,
        newColorTheme.accentColor,
        t,
      )!,
      isDark: t < 0.5 ? oldColorTheme.isDark : newColorTheme.isDark,
    );
  }
}

class NoJobThemeExtension extends ThemeExtension<NoJobThemeExtension> {
  final ColorTheme colorTheme;

  const NoJobThemeExtension({required this.colorTheme});

  @override
  ThemeExtension<NoJobThemeExtension> copyWith({ColorTheme? colorTheme}) {
    return NoJobThemeExtension(colorTheme: colorTheme ?? this.colorTheme);
  }

  @override
  ThemeExtension<NoJobThemeExtension> lerp(
    ThemeExtension<NoJobThemeExtension>? other,
    double t,
  ) {
    if (other is! NoJobThemeExtension) return this;

    return NoJobThemeExtension(
      colorTheme: ColorTheme.lerp(colorTheme, other.colorTheme, t),
    );
  }
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
