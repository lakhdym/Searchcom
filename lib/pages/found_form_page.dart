import 'package:flutter/material.dart';

/// Page de formulaire "Objet trouvé" (placeholder pour l'ÉTAPE 1)
/// Sera implémentée dans l'ÉTAPE 4
class FoundFormPage extends StatelessWidget {
  const FoundFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Objet Trouvé'),
      ),
      body: const Center(
        child: Text(
          'FoundFormPage',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
