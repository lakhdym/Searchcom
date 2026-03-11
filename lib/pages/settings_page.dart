import 'package:flutter/material.dart';

import '../services/auth_local_storage.dart';
import '../services/api_service.dart';
import '../state/auth_state.dart';
import 'home_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres'), centerTitle: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Compte', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              _SettingsSection(
                tiles: [
                  SettingsTile(
                    icon: Icons.edit_outlined,
                    title: 'Modifier le profil',
                    onTap: () => _placeholder(context),
                  ),
                  SettingsTile(
                    icon: Icons.lock_reset_outlined,
                    title: 'Changer le mot de passe',
                    onTap: () => _placeholder(context),
                  ),
                  SettingsTile(
                    icon: Icons.campaign_outlined,
                    title: 'Mes publications',
                    onTap: () => _placeholder(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Application', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              _SettingsSection(
                tiles: [
                  SettingsTile(
                    icon: Icons.language_outlined,
                    title: 'Langue',
                    subtitle: 'UI only pour le moment',
                    onTap: () => _placeholder(context),
                  ),
                  SettingsTile(
                    icon: Icons.brightness_6_outlined,
                    title: 'Thème',
                    subtitle: 'Système / Clair / Sombre',
                    onTap: () => _placeholder(context),
                  ),
                  SettingsTile(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    subtitle: 'Coming soon',
                    onTap: () => _placeholder(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Support', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              _SettingsSection(
                tiles: [
                  SettingsTile(
                    icon: Icons.help_outline,
                    title: 'Aide',
                    onTap: () => _placeholder(context),
                  ),
                  SettingsTile(
                    icon: Icons.info_outline,
                    title: 'À propos',
                    onTap: () => _placeholder(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Session', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              _SettingsSection(
                tiles: [
                  SettingsTile.danger(
                    icon: Icons.logout,
                    title: 'Déconnexion',
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

  void _placeholder(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fonctionnalité à venir.')));
  }

  Future<void> _logout(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
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
