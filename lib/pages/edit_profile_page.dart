import 'package:flutter/material.dart';

import '../core/constants/app_messages.dart';
import '../core/errors/app_error_mapper.dart';
import '../core/feedback/app_feedback.dart';
import '../core/forms/app_validators.dart';
import '../services/auth_api_service.dart';
import '../services/auth_local_storage.dart';
import '../services/l10n_helper.dart';
import '../state/auth_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _preferredLang = 'fr';
  final _avatarCtrl = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = currentUser.value;
    if (user != null) {
      _fullNameCtrl.text = user.fullName;
      _emailCtrl.text = user.email;
      _phoneCtrl.text = user.phone ?? '';
      _preferredLang = user.preferredLang;
      _avatarCtrl.text = user.avatarUrl ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = currentUser.value;
    if (user == null) {
      AppFeedback.showInfoSnackBar(context, t('reconnect_msg'));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      final updated = await AuthApiService.instance.updateProfile(
        userId: user.id,
        fullName: _fullNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        preferredLang: _preferredLang,
        avatarUrl: _avatarCtrl.text.trim().isEmpty
            ? null
            : _avatarCtrl.text.trim(),
      );
      await AuthLocalStorage.instance.saveUser(updated);
      loginUser(updated);
      if (!mounted) return;
      AppFeedback.showSuccessSnackBar(
        context,
        AppMessages.profileUpdatedSuccess(),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showErrorSnackBar(
        context,
        AppErrorMapper.message(
          e,
          fallbackMessage: AppMessages.profileUpdateError(),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final user = currentUser.value;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('edit_profile')),
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t('no_user_info')),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(t('back_to_home')),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _HeaderAvatar(
                    avatarUrl: user.avatarUrl,
                    initials: _initials(user.fullName),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(t('personal_info'), style: textTheme.titleMedium),
                        const SizedBox(height: 8),
                        _Card(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _fullNameCtrl,
                                decoration: InputDecoration(
                                  labelText: t('full_name'),
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                ),
                                validator: AppValidators.fullName,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _emailCtrl,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: t('email'),
                                  prefixIcon: const Icon(Icons.mail_outline),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: t('phone'),
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                ),
                                validator: AppValidators.phoneOptional,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(t('application'), style: textTheme.titleMedium),
                        const SizedBox(height: 8),
                        _Card(
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: _preferredLang,
                                decoration: InputDecoration(
                                  labelText: t('preferred_language'),
                                  prefixIcon: const Icon(
                                    Icons.language_outlined,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'fr',
                                    child: Text('Francais'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ar',
                                    child: Text('Arabic'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'en',
                                    child: Text('English'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _preferredLang = v ?? 'fr'),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? AppMessages.requiredField()
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _avatarCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Avatar URL',
                                  prefixIcon: const Icon(Icons.image_outlined),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _save,
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
                                : Text(t('save_changes')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    final first = parts[0][0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.avatarUrl, required this.initials});
  final String? avatarUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: scheme.primary.withValues(alpha: 0.15),
            backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                ? NetworkImage(avatarUrl!)
                : null,
            child: (avatarUrl == null || avatarUrl!.isEmpty)
                ? Text(
                    initials,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('edit_profile'), style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Photo, nom, telephone et preferences.',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
