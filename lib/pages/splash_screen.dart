import 'package:flutter/material.dart';
import '../services/language_service.dart';
import 'language_selection_page.dart';
import 'home_page.dart';

/// Splash screen : redirige vers Home si langue stockée, sinon vers le choix de langue.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LanguageService _languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await _languageService.initFromStorage();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (_languageService.hasStoredLanguage) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      await _languageService.translations.loadLanguage('fr');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LanguageSelectionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/splash.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.image, size: 80, color: Color(0xFF7C3AED)),
            );
          },
        ),
      ),
    );
  }
}
