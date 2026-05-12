import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/navigation/app_route_observer.dart';
import 'core/feedback/app_feedback.dart';
import 'pages/app_error_page.dart';
import 'pages/splash_screen.dart';
import 'services/l10n_helper.dart';
import 'services/language_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await ThemeService.instance.initFromStorage();
  await LanguageService.instance.initFromStorage();

  runApp(
    AppThemeScope(
      notifier: ThemeService.instance,
      child: AppLocaleScope(
        notifier: LanguageService.instance,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = watchTheme(context);
    final languageService = watchLanguage(context);

    return MaterialApp(
      title: t('app_title'),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AppFeedback.messengerKey,
      themeMode: themeService.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: languageService.currentLocale,
      supportedLocales: LanguageService.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorObservers: [appRouteObserver],
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => AppErrorPage.notFound()),
      builder: (context, child) {
        return Directionality(
          textDirection: languageService.textDirection,
          child: child ?? const AppErrorPage(kind: AppErrorKind.navigation),
        );
      },
      home: const SplashScreen(),
    );
  }
}
