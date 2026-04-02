import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
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

  Future<void> _sendEmailCode(BuildContext context, String email) async {
    try {
      await AuthApiService.instance.resendVerification(email: email);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => EmailVerificationPage(email: email)),
        );
      }
    }
  }

  Future<void> _sendPhoneCode(BuildContext context, String phone) async {
    try {
      await AuthApiService.instance.sendPhoneOtp(phone: phone);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => PhoneVerificationPage(phone: phone)),
        );
      }
    }
  }

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
                  onTap: () => _sendEmailCode(context, email!),
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
                  onTap: () => _sendPhoneCode(context, phone!),
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
