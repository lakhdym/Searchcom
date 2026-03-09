import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_api_service.dart';
import '../services/auth_local_storage.dart';
import '../state/auth_state.dart';
import 'home_shell.dart';
import 'login_page.dart';

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
  bool _formValid = false;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl, _passwordCtrl, _confirmCtrl]) {
      c.addListener(_updateValid);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _updateValid() {
    final valid = _nameCtrl.text.trim().length >= 2 &&
        _emailCtrl.text.contains('@') &&
        _phoneCtrl.text.trim().length >= 6 &&
        _passwordCtrl.text.length >= 8 &&
        _confirmCtrl.text == _passwordCtrl.text &&
        _accepted;
    if (valid != _formValid) setState(() => _formValid = valid);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final form = _formKey.currentState;
    if (form == null || !form.validate() || !_accepted) {
      if (!_accepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez accepter les conditions.')),
        );
      }
      return;
    }
    setState(() => _loading = true);
    try {
      final UserModel user = await AuthApiService.instance.register(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        preferredLang: 'fr',
      );
      await AuthLocalStorage.instance.saveUser(user);
      loginUser(user);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la création du compte.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                  backgroundColor: scheme.primary.withValues(alpha: 0.14),
                                  child: Icon(Icons.person_add_alt_1, color: scheme.primary),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Créer un compte',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Rejoignez la communauté',
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
                              decoration: const InputDecoration(
                                labelText: 'Nom complet',
                                hintText: 'Jean Dupont',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 2) ? 'Nom requis (min 2 caractères)' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'vous@example.com',
                                prefixIcon: Icon(Icons.mail_outlined),
                              ),
                              validator: (v) =>
                                  (v == null || !v.contains('@')) ? 'Email invalide' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Téléphone',
                                hintText: '+212 6 12 34 56 78',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 6) ? 'Téléphone invalide' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePass,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                hintText: '********',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.length < 8) ? 'Au moins 8 caractères' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                labelText: 'Confirmer le mot de passe',
                                hintText: '********',
                                prefixIcon: const Icon(Icons.lock_reset_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: (v) =>
                                  (v != _passwordCtrl.text) ? 'Les mots de passe ne correspondent pas' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _accepted,
                                  onChanged: (v) {
                                    setState(() => _accepted = v ?? false);
                                    _updateValid();
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
                                      children: [
                                        const TextSpan(text: 'J’accepte les '),
                                        TextSpan(
                                          text: 'Conditions d’utilisation',
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
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (!_formValid || _loading) ? null : _submit,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _loading
                                      ? SizedBox(
                                          key: const ValueKey('loading'),
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
                                          ),
                                        )
                                      : const Text('Créer un compte', key: ValueKey('text')),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: Divider(color: scheme.outlineVariant)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('ou', style: textTheme.bodyMedium),
                                ),
                                Expanded(child: Divider(color: scheme.outlineVariant)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: Icon(Icons.g_translate, color: scheme.primary),
                              label: const Text('Continuer avec Google'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: Icon(Icons.facebook, color: scheme.primary),
                              label: const Text('Continuer avec Facebook'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Vous avez déjà un compte ? '),
                                TextButton(
                                  onPressed: () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const LoginPage()),
                                      );
                                    }
                                  },
                                  child: const Text('Se connecter'),
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
