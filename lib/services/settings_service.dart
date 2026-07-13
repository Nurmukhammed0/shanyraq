import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { ru, kz, en }

/// Настройки приложения: тема и язык. Сохраняются на устройстве.
class SettingsService extends ChangeNotifier {
  static const _themeModeKey = 'settings.themeMode';
  static const _languageKey = 'settings.language';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  AppLanguage _language = AppLanguage.ru;
  AppLanguage get language => _language;

  SettingsService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeModeKey);
    _themeMode = switch (savedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final savedLanguage = prefs.getString(_languageKey);
    _language = switch (savedLanguage) {
      'kz' => AppLanguage.kz,
      'en' => AppLanguage.en,
      _ => AppLanguage.ru,
    };
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.name);
  }
}
