import 'dart:math';

import 'package:NoJob/features/title/ui/AppTitleProvider.dart';
import 'package:NoJob/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

extension RadExt on double {
  double toRad() => this * (pi / 180);
}

extension LogExt on String {
  String get e {
    if (kDebugMode) {
      print("==> $this");
    }

    return this;
  }
}

extension ContextExt on BuildContext {
  AppLocalizations get res => AppLocalizations.of(this)!;

  ThemeData get theme => Theme.of(this);

  NoJobThemeExtension get appTheme =>
      Theme.of(this).extension<NoJobThemeExtension>()!;
}