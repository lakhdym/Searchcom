import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../state/auth_state.dart';
import 'auth_api_service.dart';
import 'auth_local_storage.dart';
import 'translation_service.dart';

const String _kLanguageKey = 'app_language_code';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  static LanguageService get instance => _instance;
  LanguageService._internal();

  final TranslationService _translationService = TranslationService.instance;

  String _currentLanguageCode = 'fr';
  bool _hasStoredLanguage = false;
  bool _initialized = false;

  static String? _memoryLanguageCode;

  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'fr', name: 'French', nativeName: 'Francais'),
    LanguageOption(code: 'en', name: 'English', nativeName: 'English'),
    LanguageOption(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
  ];

  static const List<Locale> supportedLocales = [
    Locale('fr'),
    Locale('en'),
    Locale('ar'),
  ];

  static const Set<String> _supportedCodes = {'fr', 'en', 'ar'};

  String get currentLanguageCode => _currentLanguageCode;
  bool get hasStoredLanguage => _hasStoredLanguage;
  Locale get currentLocale => Locale(_currentLanguageCode);
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;
  bool get isRtl => _currentLanguageCode == 'ar';
  TranslationService get translations => _translationService;

  Future<bool> initFromStorage() async {
    await _translationService.preloadLanguages(_supportedCodes);

    String? storedLanguageCode;
    try {
      final prefs = await SharedPreferences.getInstance();
      storedLanguageCode = prefs.getString(_kLanguageKey);
    } catch (_) {
      storedLanguageCode = _memoryLanguageCode;
    }

    final nextCode = _normalizeLanguageCode(storedLanguageCode);
    _hasStoredLanguage =
        storedLanguageCode != null && storedLanguageCode.trim().isNotEmpty;

    final shouldNotify =
        !_initialized ||
        _currentLanguageCode != nextCode ||
        _translationService.currentLanguageCode != nextCode;

    _applyLanguage(nextCode, notify: shouldNotify);
    _initialized = true;
    return _hasStoredLanguage;
  }

  Future<void> setLanguage(
    String languageCode, {
    bool syncUserPreference = true,
  }) async {
    final nextCode = _normalizeLanguageCode(languageCode);
    await _translationService.ensureLanguageLoaded(nextCode);

    final changed =
        _currentLanguageCode != nextCode ||
        _translationService.currentLanguageCode != nextCode;

    _hasStoredLanguage = true;
    _memoryLanguageCode = nextCode;
    _applyLanguage(nextCode, notify: changed);

    unawaited(_persistLanguage(nextCode));
    if (syncUserPreference) {
      unawaited(_syncConnectedUserPreference(nextCode));
    }
  }

  Future<void> syncWithUserPreferredLanguage(String? languageCode) async {
    final nextCode = _normalizeLanguageCode(languageCode);
    if (nextCode == _currentLanguageCode) {
      return;
    }
    await setLanguage(nextCode, syncUserPreference: false);
  }

  String getLanguageName(String code) {
    return supportedLanguages
        .firstWhere(
          (lang) => lang.code == _normalizeLanguageCode(code),
          orElse: () => supportedLanguages.first,
        )
        .nativeName;
  }

  String _normalizeLanguageCode(String? code) {
    final normalized = (code ?? '').trim().toLowerCase();
    return _supportedCodes.contains(normalized) ? normalized : 'fr';
  }

  void _applyLanguage(String languageCode, {required bool notify}) {
    _currentLanguageCode = languageCode;
    _translationService.setCurrentLanguage(languageCode);
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _persistLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLanguageKey, languageCode);
    } catch (_) {
      _memoryLanguageCode = languageCode;
    }
  }

  Future<void> _syncConnectedUserPreference(String languageCode) async {
    final user = currentUser.value;
    if (user == null || user.preferredLang == languageCode) {
      return;
    }

    final optimisticUser = _copyUserWithLanguage(user, languageCode);
    currentUser.value = optimisticUser;

    String? token;
    try {
      token = await AuthLocalStorage.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await AuthLocalStorage.instance.saveSession(optimisticUser, token);
      }
    } catch (_) {
      token = null;
    }

    try {
      final remoteUser = await AuthApiService.instance.updateProfile(
        userId: optimisticUser.id,
        fullName: optimisticUser.fullName,
        email: optimisticUser.email,
        phone: optimisticUser.phone,
        preferredLang: languageCode,
        avatarUrl: optimisticUser.avatarUrl,
      );
      currentUser.value = remoteUser;
      if (token != null && token.isNotEmpty) {
        await AuthLocalStorage.instance.saveSession(remoteUser, token);
      }
    } catch (_) {
      // La synchro reseau est best-effort. L'UI reste immediate avec la copie locale.
    }
  }

  UserModel _copyUserWithLanguage(UserModel user, String languageCode) {
    return UserModel(
      id: user.id,
      role: user.role,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      preferredLang: languageCode,
      isBanned: user.isBanned,
    );
  }
}

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
