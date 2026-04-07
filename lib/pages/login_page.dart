import 'package:flutter/material.dart';

import '../core/constants/app_messages.dart';
import '../core/errors/app_error_mapper.dart';
import '../core/feedback/app_feedback.dart';
import '../core/forms/app_validators.dart';
import '../services/api_service.dart';
import '../services/auth_api_service.dart';
import '../services/auth_local_storage.dart';
import '../services/l10n_helper.dart';
import '../services/language_service.dart';
import '../state/auth_state.dart';
import 'email_verification_page.dart';
import 'home_shell.dart';
import 'phone_verification_page.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';
import 'verification_choice_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static const routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _formValid = false;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _identifierCtrl.addListener(_updateValid);
    _passwordCtrl.addListener(_updateValid);
    _restoreSession();
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    final storedUser = await AuthLocalStorage.instance.getUser();
    final storedToken = await AuthLocalStorage.instance.getToken();
    if (storedUser != null && storedToken != null && storedToken.isNotEmpty) {
      ApiService.instance.setToken(storedToken);
      loginUser(storedUser);
      await LanguageService.instance.syncWithUserPreferredLanguage(
        storedUser.preferredLang,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
      return;
    }
    if (mounted) setState(() => _checkingSession = false);
  }

  void _updateValid() {
    final valid =
        AppValidators.identifier(_identifierCtrl.text) == null &&
        AppValidators.password(_passwordCtrl.text) == null;
    if (valid != _formValid) {
      setState(() => _formValid = valid);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _loading = true);
    try {
      final session = await AuthApiService.instance.login(
        identifier: _identifierCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await AuthLocalStorage.instance.saveSession(session.user, session.token);
      ApiService.instance.setToken(session.token);
      loginUser(session.user);
      await LanguageService.instance.syncWithUserPreferredLanguage(
        session.user.preferredLang,
      );
      if (!mounted) return;
      AppFeedback.showSuccessSnackBar(context, AppMessages.loginSuccess());
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    } on EmailVerificationRequiredException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      final email = e.email ?? _identifierCtrl.text.trim();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VerificationChoicePage(
            email: email,
            phone: e.phone,
          ),
        ),
      );
    } on PhoneVerificationRequiredException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      final phone = e.phone ?? _identifierCtrl.text.trim();
      final email = _identifierCtrl.text.contains('@') ? _identifierCtrl.text.trim() : null;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => VerificationChoicePage(email: email, phone: phone)),
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showErrorSnackBar(
        context,
        AppErrorMapper.message(e, fallbackMessage: AppMessages.loginError()),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openForgotPassword() {
  }

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_checkingSession) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                                    Icons.lock_outline,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t('login'),
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      t('access_your_account'),
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
                              controller: _identifierCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: t('email_or_phone'),
                                hintText: t('email_or_phone_hint'),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: AppValidators.identifier,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: t('full_password'),
                                hintText: t('password_hint'),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: AppValidators.password,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                                  );
                                },
                                child: const Text('Mot de passe oublié ?'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (!_formValid || _loading)
                                    ? null
                                    : _submit,
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
                                          t('sign_in'),
                                          key: const ValueKey('text'),
                                        ),
                                ),
                              ),
                            ),
                            /*
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: scheme.outlineVariant),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    t('or'),
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: scheme.outlineVariant),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => AppFeedback.showInfoSnackBar(
                                context,
                                AppMessages.featureComingSoon(),
                              ),
                              icon: Icon(
                                Icons.g_translate,
                                color: scheme.primary,
                              ),
                              label: Text(t('continue_with_google')),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => AppFeedback.showInfoSnackBar(
                                context,
                                AppMessages.featureComingSoon(),
                              ),
                              icon: Icon(Icons.facebook, color: scheme.primary),
                              label: Text(t('continue_with_facebook')),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            */
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(t('no_account')),
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignUpPage(),
                                    ),
                                  ),
                                  child: Text(t('create_account')),
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

