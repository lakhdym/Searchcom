import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import 'login_page.dart';

class PhoneVerificationPage extends StatefulWidget {
  const PhoneVerificationPage({super.key, required this.phone});
  final String phone;

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _cooldown = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    if (_codeCtrl.text.trim().length < 4) return;
    setState(() => _loading = true);
    try {
      await AuthApiService.instance.verifyPhoneOtp(
        phone: widget.phone,
        code: _codeCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro vérifié avec succès')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (r) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown) return;
    setState(() => _cooldown = true);
    try {
      await AuthApiService.instance.resendPhoneOtp(phone: widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code renvoyé sur WhatsApp')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) setState(() => _cooldown = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification du numéro')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Un code a été envoyé sur WhatsApp", style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(widget.phone, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Code OTP',
                prefixIcon: Icon(Icons.lock_clock_outlined),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Vérifier'),
            ),
            TextButton(
              onPressed: _cooldown ? null : _resend,
              child: Text(_cooldown ? 'Patientez...' : 'Renvoyer le code'),
            ),
          ],
        ),
      ),
    );
  }
}
