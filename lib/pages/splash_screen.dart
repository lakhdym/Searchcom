import 'package:flutter/material.dart';
import 'language_selection_page.dart';

/// Page de splash screen affichée au lancement de l'application
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Naviguer vers la page de sélection de langue après 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LanguageSelectionPage(),
          ),
        );
      }
    });
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
            // Si l'image n'est pas trouvée, afficher un placeholder
            return Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.image,
                size: 80,
                color: Color(0xFF7C3AED),
              ),
            );
          },
        ),
      ),
    );
  }
}
