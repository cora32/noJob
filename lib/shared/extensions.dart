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
  NavigatorState get navigator => Navigator.of(this);
  AppLocalizations get res => AppLocalizations.of(this)!;

  ThemeData get theme => Theme.of(this);

  NoJobThemeExtension get appTheme =>
      Theme.of(this).extension<NoJobThemeExtension>()!;

  ScaffoldMessengerState get toaster => ScaffoldMessenger.of(this);

  void showErrorSnackBar(String textCode) {
    if (!mounted) return;

    toaster.showSnackBar(
      SnackBar(
        content: Text(textCode),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
      ),
    );
  }
}