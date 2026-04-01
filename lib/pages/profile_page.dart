import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../core/feedback/app_feedback.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_local_storage.dart';
import '../services/l10n_helper.dart';
import '../services/language_service.dart';
import '../state/auth_state.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loadingUser = false;
  String? _publicProfileUrl;

  @override
  void initState() {
    super.initState();
    _ensureUserLoaded();
  }

  Future<void> _ensureUserLoaded() async {
    if (currentUser.value != null || _loadingUser) return;
    setState(() => _loadingUser = true);
    final stored = await AuthLocalStorage.instance.getUser();
    final token = await AuthLocalStorage.instance.getToken();
    if (stored != null) {
      loginUser(stored);
      if (token != null && token.isNotEmpty) {
        ApiService.instance.setToken(token);
      }
      _publicProfileUrl = _buildProfileUrl(stored);
    }
    if (mounted) setState(() => _loadingUser = false);
  }

  String _buildProfileUrl(UserModel user) {
    return '${ApiService.baseUrlProd}/user/${user.id}';
  }

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<UserModel?>(
      valueListenable: currentUser,
      builder: (context, user, _) {
        if (_loadingUser) {
          return const Center(child: CircularProgressIndicator());
        }
        if (user == null) {
          return _EmptyProfile(
            onReconnect: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          );
        }

        final preferredLang = _langLabel(user.preferredLang);
        final roleLabel = user.role == 'admin' ? 'Admin' : t('personal_info');

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileHeaderCard(
                  user: user,
                  roleLabel: roleLabel,
                  profileUrl: _publicProfileUrl ?? _buildProfileUrl(user),
                ),
                const SizedBox(height: 16),
                Text(t('personal_info'), style: textTheme.titleMedium),
                const SizedBox(height: 8),
                _InfoSection(
                  items: [
                    _InfoItem(
                      Icons.badge_outlined,
                      t('full_name'),
                      user.fullName,
                    ),
                    _InfoItem(Icons.mail_outline, t('email'), user.email),
                    _InfoItem(
                      Icons.phone_outlined,
                      t('phone'),
                      user.phone?.isNotEmpty == true
                          ? user.phone!
                          : t('user_not_provided'),
                    ),
                    _InfoItem(
                      Icons.language_outlined,
                      t('preferred_language'),
                      preferredLang,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(t('summary'), style: textTheme.titleMedium),
                const SizedBox(height: 8),
                _StatsRow(
                  items: [
                    _StatItem(
                      label: t('active_publications_label'),
                      value: '0',
                      icon: Icons.campaign_outlined,
                    ),
                    _StatItem(
                      label: t('resolved_publications_label'),
                      value: '0',
                      icon: Icons.verified_outlined,
                    ),
                  ],
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
    if (code == null || code.isEmpty) {
      return t('user_not_provided');
    }
    return LanguageService.instance.getLanguageName(code);
  }
}

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.user,
    required this.roleLabel,
    required this.profileUrl,
  });

  final UserModel user;
  final String roleLabel;
  final String profileUrl;

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName.isEmpty
                                ? t('personal_info')
                                : user.fullName,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'copy':
                            _copyLink(context);
                            break;
                          case 'share':
                            _shareProfile();
                            break;
                          case 'qr':
                            _showQr(context);
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              const Icon(Icons.copy_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(tr(ctx, 'copy_link')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              const Icon(Icons.share_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(tr(ctx, 'share_profile')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'qr',
                          child: Row(
                            children: [
                              const Icon(Icons.qr_code_2_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(tr(ctx, 'qr_code')),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: scheme.surfaceVariant.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.more_vert, color: scheme.onSurface),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: profileUrl));
    AppFeedback.showSuccessSnackBar(context, t('link_copied'));
  }

  void _shareProfile() {
    Share.share(profileUrl, subject: t('discover_my_profile'));
  }

  void _showQr(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        watchLanguage(ctx);
        final scheme = Theme.of(ctx).colorScheme;
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr(ctx, 'qr_profile'),
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: QrImageView(
                        data: profileUrl,
                        version: QrVersions.auto,
                        size: 200,
                        foregroundColor: scheme.onSurface,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: scheme.onSurface,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      profileUrl,
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: Text(tr(ctx, 'cancel')),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        ? user.fullName
              .trim()
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .join()
              .toUpperCase()
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

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
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
                Text(
                  item.label,
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  item.value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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

class _EmptyProfile extends StatelessWidget {
  const _EmptyProfile({required this.onReconnect});

  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 54,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(tr(context, 'no_user_info'), style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              tr(context, 'reconnect_msg'),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onReconnect,
              child: Text(tr(context, 'reconnect')),
            ),
          ],
        ),
      ),
    );
  }
}
