import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeKey = 'app_theme_is_dark';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  static ThemeService get instance => _instance;
  ThemeService._internal();

  bool _isDark = false;
  bool _initialized = false;

  static bool? _memoryIsDark;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> initFromStorage() async {
    bool nextValue = _memoryIsDark ?? false;

    try {
      final prefs = await SharedPreferences.getInstance();
      nextValue = prefs.getBool(_kThemeKey) ?? nextValue;
    } catch (_) {
      nextValue = _memoryIsDark ?? false;
    }

    final shouldNotify = !_initialized || _isDark != nextValue;
    _isDark = nextValue;
    _initialized = true;

    if (shouldNotify) {
      notifyListeners();
    }
  }

  void toggleTheme(bool value) {
    if (_isDark == value) {
      return;
    }

    _isDark = value;
    _memoryIsDark = value;
    notifyListeners();

    unawaited(_persistTheme(value));
  }

  Future<void> _persistTheme(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kThemeKey, value);
    } catch (_) {
      _memoryIsDark = value;
    }
  }
}

class AppThemeScope extends InheritedNotifier<ThemeService> {
  const AppThemeScope({
    super.key,
    required ThemeService notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ThemeService of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
      return scope?.notifier ?? ThemeService.instance;
    }

    final element = context
        .getElementForInheritedWidgetOfExactType<AppThemeScope>();
    final scope = element?.widget as AppThemeScope?;
    return scope?.notifier ?? ThemeService.instance;
  }
}

ThemeService watchTheme(BuildContext context) {
  return AppThemeScope.of(context);
}

ThemeService readTheme(BuildContext context) {
  return AppThemeScope.of(context, listen: false);
}
