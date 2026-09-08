import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { ru, kz, en }

/// Настройки приложения: тема и язык. Сохраняются на устройстве.
class SettingsService extends ChangeNotifier {
  static const _themeModeKey = 'settings.themeMode';
  static const _languageKey = 'settings.language';
  static const _statusNotificationsKey = 'settings.statusNotifications';
  static const _emailNotificationsKey = 'settings.emailNotifications';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  AppLanguage _language = AppLanguage.ru;
  AppLanguage get language => _language;

  bool _statusNotifications = true;
  bool get statusNotifications => _statusNotifications;

  bool _emailNotifications = true;
  bool get emailNotifications => _emailNotifications;

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
    _statusNotifications = prefs.getBool(_statusNotificationsKey) ?? true;
    _emailNotifications = prefs.getBool(_emailNotificationsKey) ?? true;
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

  Future<void> setStatusNotifications(bool enabled) async {
    _statusNotifications = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_statusNotificationsKey, enabled);
  }

  Future<void> setEmailNotifications(bool enabled) async {
    _emailNotifications = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailNotificationsKey, enabled);
  }
}
