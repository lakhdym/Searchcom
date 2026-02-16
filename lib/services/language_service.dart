import 'package:flutter/material.dart';

/// Service de gestion de la langue de l'application
/// Stocke la langue choisie en mémoire (pas de persistance pour l'instant)
class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  /// Langue actuelle (par défaut : français)
  String _currentLanguageCode = 'fr';

  /// Getter pour la langue actuelle
  String get currentLanguageCode => _currentLanguageCode;

  /// Locale actuelle basée sur la langue choisie
  Locale get currentLocale => Locale(_currentLanguageCode);

  /// Liste des langues supportées
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'ar', name: 'Arabe', nativeName: 'العربية'),
    LanguageOption(code: 'fr', name: 'Français', nativeName: 'Français'),
    LanguageOption(code: 'en', name: 'English', nativeName: 'English'),
  ];

  /// Changer la langue
  void setLanguage(String languageCode) {
    if (_currentLanguageCode != languageCode) {
      _currentLanguageCode = languageCode;
      notifyListeners();
    }
  }

  /// Obtenir le nom de la langue à partir de son code
  String getLanguageName(String code) {
    return supportedLanguages
        .firstWhere((lang) => lang.code == code, orElse: () => supportedLanguages[1])
        .name;
  }
}

/// Classe représentant une option de langue
class LanguageOption {
  final String code;
  final String name;
  final String nativeName;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}
