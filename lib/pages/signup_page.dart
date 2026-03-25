import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../services/l10n_helper.dart';
import '../services/language_service.dart';
import 'email_verification_page.dart';
import 'login_page.dart';
import 'phone_verification_page.dart';
import 'verification_choice_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _accepted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _isEmailValid => _emailCtrl.text.trim().contains('@');
  bool get _isPhoneValid =>
      _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length >= 6;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    if (!_accepted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('please_accept_terms'))));
      return;
    }
    if (!_isEmailValid && !_isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('provide_valid_email_or_phone'))),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final resp = await AuthApiService.instance.register(
        fullName: _nameCtrl.text.trim(),
        email: _isEmailValid ? _emailCtrl.text.trim() : null,
        phone: _isPhoneValid ? _phoneCtrl.text.trim() : null,
        password: _passwordCtrl.text,
        preferredLang: LanguageService.instance.currentLanguageCode,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resp.message.isNotEmpty
                ? resp.message
                : t('account_created_success'),
          ),
        ),
      );
      final emailVal = resp.email ?? _emailCtrl.text.trim();
      final phoneVal = resp.phone ?? _phoneCtrl.text.trim();

      if (resp.requiresEmailVerification && resp.requiresPhoneVerification) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                VerificationChoicePage(email: emailVal, phone: phoneVal),
          ),
        );
      } else if (resp.requiresPhoneVerification) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PhoneVerificationPage(phone: phoneVal),
          ),
        );
      } else if (resp.requiresEmailVerification) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EmailVerificationPage(email: emailVal),
          ),
        );
      } else {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('account_creation_error'))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Container(
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth >= 900 ? 520.0 : 420.0;
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Material(
                    elevation: 8,
                    color: scheme.surface,
                    shadowColor: scheme.shadow.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: scheme.primary.withValues(
                                    alpha: 0.14,
                                  ),
                                  child: Icon(
                                    Icons.person_add_alt_1,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t('create_account'),
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      t('sign_up_subtitle'),
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: InputDecoration(
                                labelText: t('full_name'),
                                hintText: t('full_name_hint'),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                  ? t('min_2_chars')
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'vous@example.com',
                                prefixIcon: Icon(Icons.mail_outlined),
                              ).copyWith(labelText: t('email_optional')),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                return v.contains('@')
                                    ? null
                                    : t('invalid_email');
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: '+212 6 12 34 56 78',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ).copyWith(labelText: t('phone_optional')),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                return v.replaceAll(RegExp(r'\D'), '').length >=
                                        6
                                    ? null
                                    : t('invalid_phone');
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePass,
                              decoration: InputDecoration(
                                labelText: t('full_password'),
                                hintText: t('password_hint'),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePass
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass,
                                  ),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 8)
                                  ? t('at_least_8_chars')
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                labelText: t('confirm_password'),
                                hintText: t('password_hint'),
                                prefixIcon: const Icon(
                                  Icons.lock_reset_outlined,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                              ),
                              validator: (v) => (v != _passwordCtrl.text)
                                  ? t('password_mismatch')
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _accepted,
                                  onChanged: (v) {
                                    setState(() => _accepted = v ?? false);
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurface,
                                      ),
                                      children: [
                                        TextSpan(text: t('accept_terms')),
                                        TextSpan(
                                          text: ' ${t('terms_of_use')}',
                                          style: TextStyle(
                                            color: scheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _loading
                                      ? SizedBox(
                                          key: const ValueKey('loading'),
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  scheme.onPrimary,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          t('create_account'),
                                          key: const ValueKey('text'),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(t('have_account_login')),
                                TextButton(
                                  onPressed: () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginPage(),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(t('sign_in')),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
