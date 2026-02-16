import 'package:flutter/material.dart';
import 'home_page.dart';

/// Page de sélection de langue (placeholder pour l'ÉTAPE 1)
/// Sera implémentée dans l'ÉTAPE 2
class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'LanguageSelectionPage',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigation temporaire vers HomePage pour tester
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
                  ),
                );
              },
              child: const Text('Aller à HomePage (test)'),
            ),
          ],
        ),
      ),
    );
  }
}
