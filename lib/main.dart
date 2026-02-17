import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'services/language_service.dart';
import 'pages/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService();
    return ListenableBuilder(
      listenable: languageService,
      builder: (context, _) {
        return MaterialApp(
          title: 'Objets Perdus & Retrouvés',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(),
          locale: languageService.currentLocale,
          home: const SplashScreen(),
        );
      },
    );
  }
}
