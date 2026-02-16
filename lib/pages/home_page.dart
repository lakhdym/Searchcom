import 'package:flutter/material.dart';
import 'lost_form_page.dart';
import 'found_form_page.dart';

/// Page d'accueil (placeholder pour l'ÉTAPE 1)
/// Sera implémentée dans l'ÉTAPE 3
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomePage'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'HomePage',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LostFormPage(),
                  ),
                );
              },
              child: const Text('Formulaire Objet Perdu'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FoundFormPage(),
                  ),
                );
              },
              child: const Text('Formulaire Objet Trouvé'),
            ),
          ],
        ),
      ),
    );
  }
}
