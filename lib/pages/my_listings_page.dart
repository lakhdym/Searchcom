import 'package:flutter/material.dart';

import '../models/listing_model.dart';
import '../services/my_listings_api_service.dart';
import 'home_page.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  final _searchCtrl = TextEditingController();
  bool _loading = false;
  List<ListingModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await MyListingsApiService.instance.getMyListings(
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Supprimer cette publication ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await MyListingsApiService.instance.deleteListing(id);
      if (!mounted) return;
      _items.removeWhere((e) => e.id == id);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annonce supprimée')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mes publications')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomePage())),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: 'Rechercher',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _load();
                  },
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              _EmptyState(onCreate: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomePage())))
            else
              ..._items.map((e) => _ListingCard(
                    item: e,
                    onDelete: _delete,
                    onBoost: () => _showBoostSheet(e),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _showBoostSheet(ListingModel item) async {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Booster cette publication', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'Mettez votre annonce en avant pour augmenter sa visibilité.',
                style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              _BoostPlanTile(
                title: 'Plan Standard',
                subtitle: 'Mise en avant 3 jours',
                price: '29 MAD',
                icon: Icons.rocket_launch_outlined,
                color: scheme.primary,
              ),
              const SizedBox(height: 10),
              _BoostPlanTile(
                title: 'Plan Premium',
                subtitle: 'Boost 7 jours + badge premium',
                price: '59 MAD',
                icon: Icons.trending_up_rounded,
                color: scheme.secondary,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Continuer'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.item,
    required this.onDelete,
    required this.onBoost,
  });
  final ListingModel item;
  final Future<void> Function(int id) onDelete;
  final VoidCallback onBoost;

  Color _typeColor(ColorScheme scheme) => item.type == 'lost' ? Colors.red : Colors.green;

  String _statusLabel() {
    switch (item.status) {
      case 'draft':
        return 'Brouillon';
      case 'pending_payment':
        return 'En attente';
      case 'published':
        return 'Publiée';
      case 'hidden':
        return 'Cachée';
      case 'archived':
        return 'Archivée';
      default:
        return item.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Cover(url: item.coverPhotoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Badge(label: item.type == 'lost' ? "J'ai perdu" : "J'ai trouvé", color: _typeColor(scheme)),
                      const SizedBox(width: 6),
                      _Badge(label: _statusLabel(), color: scheme.primary),
                      if (item.isBoosted) ...[
                        const SizedBox(width: 6),
                        _Badge(label: 'Boostée', color: scheme.tertiary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.city ?? 'Ville inconnue',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.calendar_today, size: 14),
                      const SizedBox(width: 4),
                      Text(item.eventDate ?? item.createdAt, style: textTheme.labelMedium),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'delete') {
                  await onDelete(item.id);
                } else if (v == 'boost') {
                  onBoost();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'view', child: Text('Voir')),
                PopupMenuItem(value: 'edit', child: Text('Modifier')),
                PopupMenuItem(
                  value: 'boost',
                  child: Row(
                    children: [
                      // Icon(Icons.rocket_launch_outlined, size: 18 ),
                      // SizedBox(width: 8),
                      Text('Booster'),
                    ],
                  ),
                ),
                PopupMenuItem(value: 'delete', child: Text('Supprimer')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: url != null && url!.isNotEmpty
          ? Image.network(url!, width: 86, height: 86, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
              return _placeholder(scheme);
            })
          : _placeholder(scheme),
    );
  }

  Widget _placeholder(ColorScheme scheme) => Container(
        width: 86,
        height: 86,
        color: scheme.surfaceVariant.withOpacity(0.5),
        child: Icon(Icons.image, color: scheme.onSurfaceVariant),
      );
}

class _BoostPlanTile extends StatelessWidget {
  const _BoostPlanTile({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String price;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(price, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('Vous n’avez encore aucune publication', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Créez votre première annonce pour la voir ici.',
            style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onCreate, child: const Text('Créer une publication')),
        ],
      ),
    );
  }
}
