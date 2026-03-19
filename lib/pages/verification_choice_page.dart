import 'package:flutter/material.dart';

import 'email_verification_page.dart';
import 'phone_verification_page.dart';

class VerificationChoicePage extends StatelessWidget {
  const VerificationChoicePage({
    super.key,
    this.email,
    this.phone,
  });

  final String? email;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification du compte'),
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choisissez votre méthode de vérification',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous pouvez vérifier votre compte par email ou par numéro WhatsApp.',
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            if (email != null && email!.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primary.withOpacity(0.12),
                    child: Icon(Icons.mail_outlined, color: scheme.primary),
                  ),
                  title: const Text('Vérifier par email'),
                  subtitle: Text(email!),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => EmailVerificationPage(email: email!)),
                    );
                  },
                ),
              ),
            if (phone != null && phone!.isNotEmpty) const SizedBox(height: 12),
            if (phone != null && phone!.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.secondary.withOpacity(0.12),
                    child: Icon(Icons.sms_outlined, color: scheme.secondary),
                  ),
                  title: const Text('Vérifier par WhatsApp'),
                  subtitle: Text(phone!),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => PhoneVerificationPage(phone: phone!)),
                    );
                  },
                ),
              ),
            const Spacer(),
            Text(
              'Vous pourrez changer de méthode plus tard si besoin.',
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
