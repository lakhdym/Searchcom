import 'package:flutter/material.dart';

import '../core/constants/app_messages.dart';
import '../core/errors/app_error_mapper.dart';
import '../core/feedback/app_feedback.dart';

import '../models/listing_model.dart';
import '../services/my_listings_api_service.dart';
import '../services/api_service.dart';
import '../services/auth_local_storage.dart';
import 'found_form_page.dart';
import 'home_page.dart';

const _fallbackListingImage =
    'https://via.placeholder.com/600x400?text=Annonce';
const _uploadsBase = 'https://italents.ma/app/';

String _resolveImageUrl(String? raw) {
  final placeholder = _fallbackListingImage;
  if (raw == null) return placeholder;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return placeholder;
  if (trimmed.startsWith('http')) return trimmed;
  // Normalise les chemins relatifs comportant "uploads/..."
  String cleaned = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  final uploadsIndex = cleaned.indexOf('uploads/');
  if (uploadsIndex >= 0) {
    cleaned = cleaned.substring(uploadsIndex); // garde dÃ¨s "uploads/..."
  }
  if (cleaned.startsWith('uploads/')) {
    return '$_uploadsBase$cleaned';
  }
  // cas d'un simple nom de fichier
  return '${_uploadsBase}uploads/annonces/$cleaned';
}

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
    AuthLocalStorage.instance.getToken().then((token) {
      if (token != null && token.isNotEmpty) {
        ApiService.instance.setToken(token);
      }
    });
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
        search: _searchCtrl.text.trim().isEmpty
            ? null
            : _searchCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showErrorSnackBar(
        context,
        AppErrorMapper.message(
          e,
          fallbackMessage: AppMessages.listingsLoadError(),
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await MyListingsApiService.instance.deleteListing(id);
      if (!mounted) return;
      _items.removeWhere((e) => e.id == id);
      setState(() {});
      AppFeedback.showSuccessSnackBar(
        context,
        AppMessages.listingDeletedSuccess(),
      );
    } catch (e) {
      AppFeedback.showErrorSnackBar(
        context,
        AppErrorMapper.message(
          e,
          fallbackMessage: AppMessages.listingDeleteError(),
        ),
      );
    }
  }

  Future<void> _openDetails(ListingModel item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _ListingDetailsSheet(item: item),
    );
  }

  Future<void> _openEdit(ListingModel item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoundFormPage(
          type: item.type,
          listingId: item.id,
          initialListing: item,
          isEdit: true,
        ),
      ),
    );
    // RafraÃ®chir la liste aprÃ¨s retour
    if (mounted) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Mes publications'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const HomePage())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nouvelle'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _SearchBar(
              controller: _searchCtrl,
              onClear: () {
                _searchCtrl.clear();
                _load();
              },
              onSubmit: (_) => _load(),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              _EmptyState(
                onCreate: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const HomePage())),
              )
            else
              ..._items.map(
                (e) => _ListingCard(
                  item: e,
                  onDelete: _delete,
                  onBoost: () => _showBoostSheet(e),
                  onView: () => _openDetails(e),
                  onEdit: () => _openEdit(e),
                ),
              ),
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
              Text(
                'Booster cette publication',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mettez votre annonce en avant pour augmenter sa visibilitÃ©.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
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
    required this.onView,
    required this.onEdit,
  });
  final ListingModel item;
  final Future<void> Function(int id) onDelete;
  final VoidCallback onBoost;
  final VoidCallback onView;
  final VoidCallback onEdit;

  Color _typeColor(ColorScheme scheme) =>
      item.type == 'lost' ? Colors.red : Colors.green;

  String _statusLabel() {
    switch (item.status) {
      case 'draft':
        return 'Brouillon';
      case 'pending_payment':
        return 'En attente';
      case 'published':
        return 'PubliÃ©e';
      case 'hidden':
        return 'CachÃ©e';
      case 'archived':
        return 'ArchivÃ©e';
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
                      _Badge(
                        label: item.type == 'lost'
                            ? "J'ai perdu"
                            : "J'ai trouvÃ©",
                        color: _typeColor(scheme),
                      ),
                      const SizedBox(width: 6),
                      _Badge(label: _statusLabel(), color: scheme.primary),
                      if (item.isBoosted) ...[
                        const SizedBox(width: 6),
                        _Badge(label: 'BoostÃ©e', color: scheme.tertiary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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
                          style: textTheme.labelMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.calendar_today, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        item.eventDate ?? item.createdAt,
                        style: textTheme.labelMedium,
                      ),
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
                } else if (v == 'view') {
                  onView();
                } else if (v == 'edit') {
                  onEdit();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'view', child: Text('Voir')),
                PopupMenuItem(value: 'edit', child: Text('Modifier')),
                PopupMenuItem(
                  value: 'boost',
                  child: Row(children: [Text('Booster')]),
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
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedUrl = _resolveImageUrl(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        resolvedUrl,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(scheme),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) => Container(
    width: 110,
    height: 110,
    color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
    child: Icon(
      Icons.photo_size_select_actual_outlined,
      color: scheme.onSurfaceVariant,
    ),
  );
}

class _ListingDetailsSheet extends StatefulWidget {
  const _ListingDetailsSheet({required this.item});
  final ListingModel item;

  @override
  State<_ListingDetailsSheet> createState() => _ListingDetailsSheetState();
}

class _ListingDetailsSheetState extends State<_ListingDetailsSheet> {
  final TextEditingController _commentCtrl = TextEditingController();
  List<ApiListingComment> _comments = [];
  bool _loadingComments = false;
  String? _commentsError;
  int _likesCount = 0;
  bool _liked = false;
  bool _likeBusy = false;
  late final PageController _pageCtrl;
  int _currentImage = 0;

  List<String> get _images {
    if (widget.item.photoObjects.isNotEmpty) {
      return widget.item.photoObjects
          .map((p) => _resolveImageUrl(p.url))
          .toList();
    }
    if (widget.item.photos.isNotEmpty) {
      return widget.item.photos.map(_resolveImageUrl).toList();
    }
    return [_resolveImageUrl(widget.item.coverPhotoUrl)];
  }

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _loadComments();
    _likesCount = widget.item.likesCount;
    _liked = widget.item.likedByMe;
  }

  Future<void> _loadComments() async {
    setState(() {
      _loadingComments = true;
      _commentsError = null;
    });
    try {
      final comments = await ApiService.instance.fetchComments(widget.item.id);
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commentsError = AppErrorMapper.message(
            e,
            fallbackMessage: AppMessages.commentsLoadError(),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _addComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) {
      AppFeedback.showErrorSnackBar(context, AppMessages.commentRequired());
      return;
    }
    try {
      await ApiService.instance.addComment(
        listingId: widget.item.id,
        content: text,
      );
      _commentCtrl.clear();
      await _loadComments();
      if (mounted) {
        AppFeedback.showSuccessSnackBar(
          context,
          AppMessages.commentAddedSuccess(),
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showErrorSnackBar(
          context,
          AppErrorMapper.message(
            e,
            fallbackMessage: AppMessages.commentSendError(),
          ),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_likeBusy) return;
    setState(() => _likeBusy = true);
    try {
      final LikeToggleResult res = await ApiService.instance.toggleLike(
        widget.item.id,
      );
      if (mounted) {
        setState(() {
          _liked = res.liked;
          _likesCount = res.likesCount;
        });
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showErrorSnackBar(
          context,
          AppErrorMapper.message(
            e,
            fallbackMessage: AppMessages.likeUpdateError(),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (ctx, controller) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              SizedBox(
                height: 240,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    PageView.builder(
                      controller: _pageCtrl,
                      onPageChanged: (i) => setState(() => _currentImage = i),
                      itemCount: _images.length,
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _images[i],
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                          (progress.expectedTotalBytes ?? 1)
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: scheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_images.length > 1)
                      Positioned(
                        bottom: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_images.length, (i) {
                            final active = i == _currentImage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: 8,
                              width: active ? 16 : 8,
                              decoration: BoxDecoration(
                                color: active
                                    ? scheme.surface
                                    : scheme.surface.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.item.title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Badge(
                    label: widget.item.type == 'lost'
                        ? "J'ai perdu"
                        : "J'ai trouvÃ©",
                    color: widget.item.type == 'lost'
                        ? Colors.red
                        : Colors.green,
                  ),
                  const SizedBox(width: 6),
                  _Badge(
                    label: _statusLabel(widget.item.status),
                    color: scheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.place, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.item.city ?? 'Ville inconnue',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    widget.item.eventDate ?? widget.item.createdAt,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(widget.item.description, style: textTheme.bodyMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: _likeBusy ? null : _toggleLike,
                    icon: Icon(
                      _liked ? Icons.favorite : Icons.favorite_border,
                      color: _liked ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ),
                  Text('$_likesCount'),
                  const SizedBox(width: 16),
                  const Icon(Icons.comment_outlined, size: 20),
                  const SizedBox(width: 6),
                  Text('${_comments.length}'),
                ],
              ),
              const SizedBox(height: 12),
              Text('Commentaires', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_loadingComments)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_commentsError != null)
                Text(_commentsError!, style: TextStyle(color: scheme.error))
              else if (_comments.isEmpty)
                Text(
                  'Aucun commentaire pour le moment',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                ..._comments.map(
                  (c) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: scheme.primary.withOpacity(0.1),
                      child: Text(
                        c.fullName.isNotEmpty
                            ? c.fullName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(
                      c.fullName,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(c.content),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentCtrl,
                decoration: InputDecoration(
                  labelText: 'Ajouter un commentaire',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _addComment,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'pending_payment':
        return 'En attente';
      case 'published':
        return 'PubliÃ©e';
      case 'hidden':
        return 'CachÃ©e';
      case 'archived':
        return 'ArchivÃ©e';
      default:
        return status;
    }
  }
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
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onClear,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 2,
      shadowColor: scheme.shadow.withOpacity(0.05),
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmit,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search),
          hintText: 'Rechercher une publication',
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: onClear,
          ),
        ),
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
          Text(
            'Vous nâ€™avez encore aucune publication',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'CrÃ©ez votre premiÃ¨re annonce pour la voir ici.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onCreate,
            child: const Text('CrÃ©er une publication'),
          ),
        ],
      ),
    );
  }
}
