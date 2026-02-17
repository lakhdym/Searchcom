import 'package:flutter/material.dart';

/// Page de formulaire "Objet perdu" (placeholder pour l'ÉTAPE 1)
/// Sera implémentée dans l'ÉTAPE 4
class LostFormPage extends StatelessWidget {
  const LostFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Objet Perdu')),
      body: const Center(
        child: Text(
          'Lost Form Page',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
