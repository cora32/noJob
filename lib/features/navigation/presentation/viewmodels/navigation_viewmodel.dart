import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppScreen { dashboard, fullLog }

class NavigationViewModel extends Notifier<AppScreen> {
  @override
  AppScreen build() => AppScreen.dashboard;

  void navigateTo(AppScreen screen) {
    state = screen;
  }

  void goBack() {
    state = AppScreen.dashboard;
  }
}
