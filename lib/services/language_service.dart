import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translation_service.dart';

/// Clé SharedPreferences pour la langue
const String _kLanguageKey = 'app_language_code';

/// Service de gestion de la langue de l'application
/// Persiste la langue avec SharedPreferences (ou en mémoire sur web si le plugin échoue).
class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  final TranslationService _translationService = TranslationService();

  /// Langue actuelle (par défaut : français)
  String _currentLanguageCode = 'fr';

  /// True si une langue a déjà été enregistrée (utilisateur a déjà choisi)
  bool _hasStoredLanguage = false;

  /// Fallback en mémoire quand SharedPreferences n'est pas dispo (ex. web)
  static String? _memoryLanguageCode;

  /// Getter pour la langue actuelle
  String get currentLanguageCode => _currentLanguageCode;

  /// Indique si une langue est déjà stockée (rediriger vers l'accueil)
  bool get hasStoredLanguage => _hasStoredLanguage;

  /// Locale actuelle basée sur la langue choisie
  Locale get currentLocale => Locale(_currentLanguageCode);

  /// Liste des langues supportées
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'ar', name: 'Arabe', nativeName: 'العربية'),
    LanguageOption(code: 'fr', name: 'Français', nativeName: 'Français'),
    LanguageOption(code: 'en', name: 'English', nativeName: 'English'),
  ];

  /// Charge la langue depuis SharedPreferences au démarrage (ou mémoire)
  /// Retourne true si une langue était déjà stockée (aller à l'accueil)
  Future<bool> initFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_kLanguageKey);
      if (stored != null && stored.isNotEmpty) {
        _currentLanguageCode = stored;
        _hasStoredLanguage = true;
        await _translationService.loadLanguage(stored);
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Sur le web, le plugin peut lever MissingPluginException au premier chargement
      // Fallback : utiliser le stockage en mémoire
      final fromMemory = _memoryLanguageCode;
      if (fromMemory != null && fromMemory.isNotEmpty) {
        _currentLanguageCode = fromMemory;
        _hasStoredLanguage = true;
        await _translationService.loadLanguage(fromMemory);
        notifyListeners();
        return true;
      }
    }

    _hasStoredLanguage = false;
    notifyListeners();
    return false;
  }

  /// Changer la langue, persister et charger les traductions
  Future<void> setLanguage(String languageCode) async {
    if (_currentLanguageCode == languageCode && _translationService.isLoaded) {
      return;
    }
    _currentLanguageCode = languageCode;
    _hasStoredLanguage = true;
    _memoryLanguageCode = languageCode;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLanguageKey, languageCode);
    } catch (_) {
      // Persistance en mémoire uniquement si SharedPreferences indisponible (ex. web)
    }

    await _translationService.loadLanguage(languageCode);
    notifyListeners();
  }

  /// Obtenir le nom de la langue à partir de son code
  String getLanguageName(String code) {
    return supportedLanguages
        .firstWhere(
          (lang) => lang.code == code,
          orElse: () => supportedLanguages[1],
        )
        .name;
  }

  /// Accès au service de traduction (pour t('key'))
  TranslationService get translations => _translationService;
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
