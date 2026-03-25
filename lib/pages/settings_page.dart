import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_local_storage.dart';
import '../services/l10n_helper.dart';
import '../services/language_service.dart';
import '../state/auth_state.dart';
import 'change_password_page.dart';
import 'edit_profile_page.dart';
import 'home_page.dart';
import 'my_listings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showLanguagePicker(BuildContext context) {
    final languageService = LanguageService.instance;
    showDialog(
      context: context,
      builder: (ctx) {
        watchLanguage(ctx);
        return AlertDialog(
          title: Text(tr(ctx, 'select_language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: LanguageService.supportedLanguages.map((lang) {
              final isSelected =
                  languageService.currentLanguageCode == lang.code;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: isSelected
                      ? Icon(
                          Icons.check,
                          color: Theme.of(ctx).colorScheme.primary,
                        )
                      : null,
                  title: Text(lang.nativeName),
                  subtitle: Text(lang.name),
                  onTap: () async {
                    await languageService.setLanguage(lang.code);
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = watchLanguage(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'settings')), centerTitle: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(context, 'account_settings'),
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _SettingsSection(
                tiles: [
                  SettingsTile(
                    icon: Icons.edit_outlined,
                    title: t('edit_profile'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfilePage(),
                      ),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.lock_reset_outlined,
                    title: t('change_password'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordPage(),
                      ),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.campaign_outlined,
                    title: t('my_listings'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyListingsPage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(tr(context, 'application'), style: textTheme.titleMedium),
              const SizedBox(height: 8),
              _SettingsSection(
                tiles: [
                  SettingsTile(
                    icon: Icons.language_outlined,
                    title: t('select_language'),
                    subtitle: languageService.getLanguageName(
                      languageService.currentLanguageCode,
                    ),
                    onTap: () => _showLanguagePicker(context),
                  ),
                  SettingsTile(
                    icon: Icons.brightness_6_outlined,
                    title: t('theme'),
                    subtitle: t('system_light_dark'),
                    onTap: () => _showComingSoon(context),
                  ),
                  SettingsTile(
                    icon: Icons.notifications_none,
                    title: t('notifications'),
                    subtitle: t('coming_soon'),
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(tr(context, 'support'), style: textTheme.titleMedium),
              const SizedBox(height: 8),
              _SettingsSection(
                tiles: [
                  SettingsTile(
                    icon: Icons.help_outline,
                    title: t('help'),
                    onTap: () => _showComingSoon(context),
                  ),
                  SettingsTile(
                    icon: Icons.info_outline,
                    title: t('about'),
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(tr(context, 'session'), style: textTheme.titleMedium),
              const SizedBox(height: 8),
              _SettingsSection(
                tiles: [
                  SettingsTile.danger(
                    icon: Icons.logout,
                    title: t('logout_confirm'),
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t('feature_coming'))));
  }

  Future<void> _logout(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        watchLanguage(ctx);
        return AlertDialog(
          title: Text(tr(ctx, 'logout_confirm')),
          content: Text(tr(ctx, 'logout_confirm_msg')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(ctx, 'cancel_button')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              child: Text(tr(ctx, 'logout_confirm')),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    await AuthLocalStorage.instance.clear();
    ApiService.instance.setToken(null);
    logoutUser();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.tiles});

  final List<SettingsTile> tiles;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
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
      child: Column(
        children: List.generate(tiles.length, (index) {
          final tile = tiles[index];
          final isLast = index == tiles.length - 1;
          return Column(
            children: [
              tile,
              if (!isLast)
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.color,
  }) : isDanger = false;

  const SettingsTile.danger({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  }) : color = null,
       isDanger = true;

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final resolvedColor = isDanger ? scheme.error : (color ?? scheme.primary);

    return ListTile(
      leading: Icon(icon, color: resolvedColor),
      title: Text(
        title,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDanger ? scheme.error : scheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
