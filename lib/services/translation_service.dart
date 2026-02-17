import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service de traduction chargé depuis les fichiers JSON dans assets/lang/
class TranslationService extends ChangeNotifier {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final Map<String, Map<String, String>> _cache = {};
  String _currentLanguageCode = 'fr';

  String get currentLanguageCode => _currentLanguageCode;

  Future<void> loadLanguage(String languageCode) async {
    if (_cache.containsKey(languageCode)) {
      _currentLanguageCode = languageCode;
      notifyListeners();
      return;
    }
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/lang/$languageCode.json',
      );
      final Map<String, dynamic> decoded = json.decode(jsonString) as Map<String, dynamic>;
      final Map<String, String> translations = decoded.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      _cache[languageCode] = translations;
      _currentLanguageCode = languageCode;
      notifyListeners();
    } catch (e) {
      if (languageCode != 'fr') {
        await loadLanguage('fr');
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
}
