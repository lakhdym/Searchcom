import 'package:flutter/widgets.dart';

import 'language_service.dart';

class AppLocaleScope extends InheritedNotifier<LanguageService> {
  const AppLocaleScope({
    super.key,
    required LanguageService notifier,
    required super.child,
  }) : super(notifier: notifier);

  static LanguageService of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final scope = context
          .dependOnInheritedWidgetOfExactType<AppLocaleScope>();
      return scope?.notifier ?? LanguageService.instance;
    }

    final element = context
        .getElementForInheritedWidgetOfExactType<AppLocaleScope>();
    final scope = element?.widget as AppLocaleScope?;
    return scope?.notifier ?? LanguageService.instance;
  }
}

/// Helper pour acceder aux traductions de maniere simple.
String t(String key) {
  return LanguageService.instance.translations.t(key);
}

/// Variante reactive qui inscrit le widget courant a la langue globale.
String tr(BuildContext context, String key) {
  watchLanguage(context);
  return t(key);
}

LanguageService watchLanguage(BuildContext context) {
  return AppLocaleScope.of(context);
}

LanguageService readLanguage(BuildContext context) {
  return AppLocaleScope.of(context, listen: false);
}

String getCurrentLanguageCode() {
  return LanguageService.instance.currentLanguageCode;
}

bool isArabic() {
  return LanguageService.instance.isRtl;
}

bool isArabicContext(BuildContext context) {
  return watchLanguage(context).isRtl;
}

LanguageService getLanguageService() {
  return LanguageService.instance;
}
