import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service de traduction charge depuis les fichiers JSON dans assets/lang/.
class TranslationService extends ChangeNotifier {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  static TranslationService get instance => _instance;
  TranslationService._internal();

  final Map<String, Map<String, String>> _cache = {};
  String _currentLanguageCode = 'fr';

  String get currentLanguageCode => _currentLanguageCode;

  Future<void> preloadLanguages(Iterable<String> languageCodes) async {
    for (final languageCode in languageCodes) {
      await _loadIntoCache(languageCode);
    }
  }

  Future<void> loadLanguage(String languageCode) async {
    await _loadIntoCache(languageCode);
    setCurrentLanguage(languageCode);
  }

  Future<void> ensureLanguageLoaded(String languageCode) async {
    await _loadIntoCache(languageCode);
  }

  void setCurrentLanguage(String languageCode) {
    if (_currentLanguageCode == languageCode &&
        _cache.containsKey(languageCode)) {
      return;
    }
    _currentLanguageCode = languageCode;
    notifyListeners();
  }

  Future<void> _loadIntoCache(String languageCode) async {
    if (_cache.containsKey(languageCode)) {
      return;
    }

    try {
      final jsonString = await rootBundle.loadString(
        'assets/lang/$languageCode.json',
      );
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      final translations = decoded.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      _cache[languageCode] = translations;
    } catch (e) {
      if (languageCode != 'fr') {
        await _loadIntoCache('fr');
      } else {
        rethrow;
      }
    }
  }

  String translate(String key) {
    final translations = _cache[_currentLanguageCode];
    if (translations == null) return key;
    return translations[key] ?? key;
  }

  String t(String key) => translate(key);
  bool get isLoaded => _cache.containsKey(_currentLanguageCode);
  bool isLanguageLoaded(String languageCode) =>
      _cache.containsKey(languageCode);
}
