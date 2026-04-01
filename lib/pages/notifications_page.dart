import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_local_storage.dart';
import '../models/user_model.dart';
import '../models/listing_model.dart';
import '../widgets/home/home_models.dart';
import '../widgets/home/publication_full_details_sheet.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;
  String? _error;
  List<ApiNotification> _items = [];
  int _unseenCount = 0;
  UserModel? _me;
  final String _fallbackImage = 'https://via.placeholder.com/600x400?text=Annonce';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _me = await AuthLocalStorage.instance.getUser();
      if (_me == null) {
        setState(() => _error = 'Connectez-vous pour voir vos notifications.');
        return;
      }
      var lastSeen = await AuthLocalStorage.instance.getLastNotifSeen();
      if (lastSeen == null) {
        lastSeen = DateTime.now();
        await AuthLocalStorage.instance.setLastNotifSeen(lastSeen);
      }
      final counts = await ApiService.instance.fetchNotifications(
        userId: _me!.id,
        since: lastSeen,
        countOnly: true,
      );
      final unseen = counts.length;
      final data = await ApiService.instance.fetchNotifications(
        userId: _me!.id,
        since: null, // charge tout pour l'instant
      );
      setState(() {
        _items = data;
        _unseenCount = unseen;
      });
      // Marque comme lu jusqu'à la notification la plus récente
      DateTime seenAt = DateTime.now();
      if (data.isNotEmpty) {
        final newest = data.map((e) => e.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
        seenAt = newest.isAfter(seenAt) ? newest : seenAt;
      }
      await AuthLocalStorage.instance.setLastNotifSeen(seenAt);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _resolveImageUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return _fallbackImage;
    final t = raw.trim();
    if (t.startsWith('http')) return t;
    final cleaned = t.startsWith('/') ? t.substring(1) : t;
    if (cleaned.startsWith('uploads/')) {
      return 'https://italents.ma/app/$cleaned';
    }
    return 'https://italents.ma/app/uploads/annonces/$cleaned';
  }

  Future<void> _openSource(ApiNotification n) async {
    try {
      final me = await AuthLocalStorage.instance.getUser();
      final listing = await ApiService.instance.fetchListingById(
        listingId: n.listingId,
        userId: me?.id,
      );
      if (!mounted) return;
      final images = (listing.photos.isNotEmpty
              ? listing.photos
              : (listing.coverPhotoUrl != null ? [listing.coverPhotoUrl!] : <String>[]))
          .map(_resolveImageUrl)
          .toList();
      final publication = Publication(
        id: listing.id,
        ownerId: listing.userId,
        title: listing.title,
        status: listing.type == 'found' ? PublicationStatus.trouve : PublicationStatus.perdu,
        imageUrls: images.isNotEmpty ? images : [_fallbackImage],
        dateText: listing.createdAt,
        eventDate: listing.eventDate ?? '',
        description: listing.description,
        cityArea: listing.city ?? listing.locationText ?? '',
        likesCount: listing.likesCount,
        commentsCount: listing.commentsCount,
        likedByMe: listing.likedByMe,
        contactChat: listing.contactChat,
        contactWhatsApp: listing.contactWhatsApp,
        contactCall: listing.contactCall,
        ownerPhone: null,
        ownerName: null,
      );
      final scheme = Theme.of(context).colorScheme;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (_) => PublicationFullDetailsSheet(
          publication: publication,
          red: Colors.red,
          green: Colors.green,
          textGray: scheme.onSurfaceVariant,
          mutedGray: scheme.outline,
          purple: scheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir l\'annonce: $e')),
      );
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: scheme.surface,
        elevation: 0.4,
      ),
      backgroundColor: scheme.surface,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!, style: TextStyle(color: scheme.error)),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _items.length + (_unseenCount > 0 ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (_unseenCount > 0 && index == 0) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_unseenCount notification(s) non lue(s)',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        );
                      }
                      final n = _items[index - (_unseenCount > 0 ? 1 : 0)];
                      final isLike = (n.type.toLowerCase() == 'like');
                      final icon = isLike ? Icons.favorite_border : Icons.chat_bubble_outline;
                      final bgColor = scheme.primaryContainer;
                      final fgColor = scheme.primary;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openSource(n),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.surfaceVariant.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: bgColor,
                                  child: Icon(icon, color: fgColor, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${n.actorName} ${isLike ? "a aimé" : "a commenté"} votre annonce',
                                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      if (n.listingTitle.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            n.listingTitle,
                                            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                          ),
                                        ),
                                      if (!isLike && (n.content?.isNotEmpty ?? false))
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            '"${n.content}"',
                                            style: textTheme.bodySmall,
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          _formatTime(n.createdAt),
                                          style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
