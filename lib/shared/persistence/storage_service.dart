import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const _themeKey = 'selected_theme_index';

  Future<void> setThemeIndex(int index) async {
    await _prefs.setInt(_themeKey, index);
  }

  int? getThemeIndex() {
    return _prefs.getInt(_themeKey);
  }
}

// Provider that should be initialized in main.dart
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError(
    'storageServiceProvider must be overridden in ProviderScope',
  );
});
