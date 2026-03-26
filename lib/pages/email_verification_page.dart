import 'package:flutter/material.dart';

import '../core/constants/app_messages.dart';
import '../core/errors/app_error_mapper.dart';
import '../core/feedback/app_feedback.dart';
import '../core/forms/app_validators.dart';
import '../services/auth_api_service.dart';
import '../services/l10n_helper.dart';
import 'login_page.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key, required this.email});

  final String email;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _codeCtrl = TextEditingController();
  bool _loadingVerify = false;
  bool _loadingResend = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    final validation = AppValidators.verificationCode(_codeCtrl.text.trim());
    if (validation != null) {
      AppFeedback.showErrorSnackBar(context, validation);
      return;
    }
    setState(() => _loadingVerify = true);
    try {
      await AuthApiService.instance.verifyEmail(
        email: widget.email,
        code: _codeCtrl.text.trim(),
      );
      if (!mounted) return;
      AppFeedback.showSuccessSnackBar(
        context,
        AppMessages.emailVerifiedSuccess(),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
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
      if (mounted) setState(() => _loadingVerify = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _loadingResend = true);
    try {
      await AuthApiService.instance.resendVerification(email: widget.email);
      if (!mounted) return;
      AppFeedback.showSuccessSnackBar(context, AppMessages.codeResentSuccess());
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showErrorSnackBar(
        context,
        AppErrorMapper.message(
          e,
          fallbackMessage: AppMessages.codeResendError(),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingResend = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification email'),
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withValues(alpha: 0.06),
              scheme.secondaryContainer.withValues(alpha: 0.04),
              scheme.surfaceTint.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                color: scheme.surface,
                elevation: 8,
                shadowColor: scheme.shadow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: scheme.primary.withValues(alpha: 0.14),
                        child: Icon(
                          Icons.mark_email_read_outlined,
                          size: 30,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Verifiez votre email',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Un code a ete envoye a ${widget.email}. Saisissez-le pour activer votre compte.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _codeCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Code a 6 chiffres',
                          prefixIcon: Icon(Icons.verified_outlined),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loadingVerify ? null : _verify,
                          child: _loadingVerify
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      scheme.onPrimary,
                                    ),
                                  ),
                                )
                              : const Text('Verifier'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loadingResend ? null : _resend,
                        child: _loadingResend
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    scheme.primary,
                                  ),
                                ),
                              )
                            : const Text('Renvoyer le code'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Le code expire dans 10 minutes.',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
