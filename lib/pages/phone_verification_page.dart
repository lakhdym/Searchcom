import 'package:flutter/material.dart';

import '../core/constants/app_messages.dart';
import '../core/errors/app_error_mapper.dart';
import '../core/feedback/app_feedback.dart';
import '../core/forms/app_validators.dart';
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
    final validation = AppValidators.verificationCode(
      _codeCtrl.text.trim(),
      minLength: 4,
    );
    if (validation != null) {
      AppFeedback.showErrorSnackBar(context, validation);
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthApiService.instance.verifyPhoneOtp(
        phone: widget.phone,
        code: _codeCtrl.text.trim(),
      );
      if (!mounted) return;
      AppFeedback.showSuccessSnackBar(
        context,
        AppMessages.phoneVerifiedSuccess(),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showErrorSnackBar(
        context,
        AppErrorMapper.message(
          e,
          fallbackMessage: AppMessages.verificationError(),
        ),
      );
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
      AppFeedback.showSuccessSnackBar(context, AppMessages.codeResentSuccess());
    } catch (e) {
      if (mounted) {
        AppFeedback.showErrorSnackBar(
          context,
          AppErrorMapper.message(
            e,
            fallbackMessage: AppMessages.codeResendError(),
          ),
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
      appBar: AppBar(title: const Text('Verification du numero')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Un code a ete envoye sur WhatsApp',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.phone,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
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
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verifier'),
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
