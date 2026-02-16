import 'package:flutter/material.dart';

/// Page de liste des publications (placeholder pour l'ÉTAPE 1)
/// Sera implémentée dans l'ÉTAPE 6
class PublicationsPage extends StatelessWidget {
  const PublicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publications'),
      ),
      body: const Center(
        child: Text(
          'PublicationsPage',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
