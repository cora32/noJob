import 'dart:math';

import 'package:flutter/foundation.dart';

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