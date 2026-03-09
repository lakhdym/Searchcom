import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_local_storage.dart';
import '../state/auth_state.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loadingUser = false;

  @override
  void initState() {
    super.initState();
    _ensureUserLoaded();
  }

  Future<void> _ensureUserLoaded() async {
    if (currentUser.value != null || _loadingUser) return;
    setState(() => _loadingUser = true);
    final stored = await AuthLocalStorage.instance.getUser();
    if (stored != null) {
      loginUser(stored);
    }
    if (mounted) setState(() => _loadingUser = false);
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthLocalStorage.instance.clear();
    logoutUser();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<UserModel?>(
      valueListenable: currentUser,
      builder: (context, user, _) {
        if (_loadingUser) {
          return const Center(child: CircularProgressIndicator());
        }
        if (user == null) {
          return _EmptyProfile(onReconnect: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          });
        }

        final preferredLang = _langLabel(user.preferredLang);
        final roleLabel = user.role == 'admin' ? 'Admin' : 'Utilisateur';

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileHeaderCard(user: user, roleLabel: roleLabel),
                const SizedBox(height: 16),
                Text('Informations personnelles', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                _InfoSection(
                  items: [
                    _InfoItem(Icons.badge_outlined, 'Nom complet', user.fullName),
                    _InfoItem(Icons.mail_outline, 'Email', user.email),
                    _InfoItem(Icons.phone_outlined, 'Téléphone', user.phone?.isNotEmpty == true ? user.phone! : 'Non renseigné'),
                    _InfoItem(Icons.language_outlined, 'Langue préférée', preferredLang),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Résumé', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                _StatsRow(
                  items: const [
                    _StatItem(label: 'Publications actives', value: '0', icon: Icons.campaign_outlined),
                    _StatItem(label: 'Publications résolues', value: '0', icon: Icons.verified_outlined),
                    _StatItem(label: 'Messages', value: '0', icon: Icons.chat_bubble_outline),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Compte', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                _ActionSection(
                  onLogout: () => _logout(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  String _langLabel(String? code) {
    switch (code) {
      case 'ar':
        return 'Arabe';
      case 'en':
        return 'Anglais';
      case 'fr':
        return 'Français';
      default:
        return 'Non renseigné';
    }
  }
}

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({super.key, required this.user, required this.roleLabel});

  final UserModel user;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(user: user),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isEmpty ? 'Utilisateur' : user.fullName,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    roleLabel,
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = user.fullName.isNotEmpty
        ? user.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase()
        : 'U';
    return CircleAvatar(
      radius: 34,
      backgroundColor: scheme.primary.withValues(alpha: 0.15),
      backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
          ? NetworkImage(user.avatarUrl!)
          : null,
      child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
          ? Text(
              initials.length > 2 ? initials.substring(0, 2) : initials,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            )
          : null,
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.items});
  final List<_InfoItem> items;

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
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, color: scheme.primary),
                title: Text(item.label),
                subtitle: Text(item.value),
                dense: false,
              ),
              if (!isLast) Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.6)),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.items});
  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 640;
        final crossAxisCount = isWide ? items.length : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWide ? 2.4 : 3.2,
          children: items.map((e) => _StatCard(item: e)).toList(),
        );
      },
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem({required this.label, required this.value, required this.icon});
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});
  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.label, style: textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                Text(
                  item.value,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({required this.onLogout});
  final VoidCallback onLogout;

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
        children: [
          _actionTile(context, Icons.edit_outlined, 'Modifier le profil', onTap: () {}),
          _divider(context),
          _actionTile(context, Icons.lock_reset_outlined, 'Changer le mot de passe', onTap: () {}),
          _divider(context),
          _actionTile(context, Icons.campaign_outlined, 'Mes publications', onTap: () {}),
          _divider(context),
          _actionTile(context, Icons.settings_outlined, 'Paramètres', onTap: () {}),
          _divider(context),
          _actionTile(
            context,
            Icons.logout,
            'Déconnexion',
            color: scheme.error,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.6));
  }

  Widget _actionTile(BuildContext context, IconData icon, String label,
      {VoidCallback? onTap, Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: color ?? scheme.primary),
      title: Text(label,
          style: TextStyle(
            color: color ?? scheme.onSurface,
            fontWeight: FontWeight.w600,
          )),
      trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

class _EmptyProfile extends StatelessWidget {
  const _EmptyProfile({required this.onReconnect});
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, size: 54, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Aucune information utilisateur disponible', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Veuillez vous reconnecter pour voir votre profil.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onReconnect,
              child: const Text('Se reconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}
