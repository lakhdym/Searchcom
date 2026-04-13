import 'package:flutter/material.dart';

import '../core/constants/app_messages.dart';
import '../core/errors/app_error_mapper.dart';
import '../core/feedback/app_feedback.dart';
import '../core/forms/app_validators.dart';
import '../services/auth_api_service.dart';
import '../services/l10n_helper.dart';
import 'main_app_shell.dart';
import '../state/auth_state.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = currentUser.value;
    if (user == null) {
      AppFeedback.showInfoSnackBar(context, t('reconnect_msg'));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await AuthApiService.instance.changePassword(
        userId: user.id,
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (!mounted) return;
      AppFeedback.showSuccessSnackBar(
        context,
        AppMessages.passwordUpdatedSuccess(),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showErrorSnackBar(
        context,
        AppErrorMapper.message(
          e,
          fallbackMessage: AppMessages.passwordUpdateError(),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AuthenticatedScaffold(
      currentIndex: mainAppShellSettingsIndex,
      appBar: AppBar(title: Text(t('change_password'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Securite', style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _passwordField(
                      controller: _currentCtrl,
                      label: t('password'),
                      obscure: _obscureCurrent,
                      toggle: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                      validator: AppValidators.currentPassword,
                    ),
                    const SizedBox(height: 12),
                    _passwordField(
                      controller: _newCtrl,
                      label: t('new_password'),
                      obscure: _obscureNew,
                      toggle: () => setState(() => _obscureNew = !_obscureNew),
                      validator: AppValidators.password,
                    ),
                    const SizedBox(height: 12),
                    _passwordField(
                      controller: _confirmCtrl,
                      label: t('confirm_password'),
                      obscure: _obscureConfirm,
                      toggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) =>
                          AppValidators.confirmPassword(v, _newCtrl.text),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
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
                    : Text(t('change_password')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
