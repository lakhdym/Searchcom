import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_local_storage.dart';
import '../services/language_service.dart';
import '../state/auth_state.dart';
import 'home_page.dart';
import 'language_selection_page.dart';
import 'main_app_shell.dart';

/// Splash screen : redirige vers Home si langue stockee, sinon vers le choix de langue.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LanguageService _languageService = LanguageService.instance;

  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final storedUser = await AuthLocalStorage.instance.getUser();
    final storedToken = await AuthLocalStorage.instance.getToken();

    if (storedUser != null && storedToken != null && storedToken.isNotEmpty) {
      ApiService.instance.setToken(storedToken);
      loginUser(storedUser);
      await _languageService.syncWithUserPreferredLanguage(
        storedUser.preferredLang,
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainAppShell()));
      return;
    }

    if (!mounted) return;

    if (_languageService.hasStoredLanguage) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LanguageSelectionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Image.asset(
          'assets/images/splash.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.image, size: 80, color: scheme.primary),
            );
          },
        ),
      ),
    );
  }
}
