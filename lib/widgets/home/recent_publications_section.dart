import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'filter_segmented_control.dart';
import 'home_models.dart';
import 'publication_card.dart';

class RecentPublicationsSection extends StatefulWidget {
  const RecentPublicationsSection({
    super.key,
    this.headerBuilder,
    this.scrollController,
    this.refreshListenable,
  });

  final HeaderBuilder? headerBuilder;
  final ScrollController? scrollController;
  final ValueListenable<int>? refreshListenable;

  @override
  State<RecentPublicationsSection> createState() =>
      _RecentPublicationsSectionState();
}

class _RecentPublicationsSectionState extends State<RecentPublicationsSection> {
  static const _purple = Color(0xFF6C2BFF);
  static const _red = Color(0xFFFF3B30);
  static const _green = Color(0xFF34C759);
  static const _textGray = Color(0xFF6B7280);
  static const _mutedGray = Color(0xFF9CA3AF);
  static const _pageSize = 5;
  static const _loadMoreSize = 1;
  static const _prefetchThreshold = 180.0;

  List<Publication> _publications = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;
  int _requestSerial = 0;

  int _selectedIndex = 0; // 0: Tout, 1: Perdu, 2: Trouvé
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_handleScroll);
    widget.refreshListenable?.addListener(_handleExternalRefresh);
    _refreshFeed();
  }

  @override
  void didUpdateWidget(covariant RecentPublicationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_handleScroll);
      widget.scrollController?.addListener(_handleScroll);
    }
    if (oldWidget.refreshListenable != widget.refreshListenable) {
      oldWidget.refreshListenable?.removeListener(_handleExternalRefresh);
      widget.refreshListenable?.addListener(_handleExternalRefresh);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_handleScroll);
    widget.refreshListenable?.removeListener(_handleExternalRefresh);
    super.dispose();
  }

  String? get _selectedType {
    switch (_selectedIndex) {
      case 1:
        return 'lost';
      case 2:
        return 'found';
      default:
        return null;
    }
  }

  void _handleScroll() {
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return;
    if (_loading || _loadingMore || !_hasMore) return;
    if (controller.position.extentAfter > _prefetchThreshold) return;
    _loadPublications();
  }

  void _handleExternalRefresh() {
    _refreshFeed();
  }

  Future<void> _refreshFeed() async {
    await _loadPublications(reset: true);
  }

  Publication _mapListing(ApiListing listing) {
    final images = listing.images.isNotEmpty
        ? listing.images
        : (listing.imageUrl != null && listing.imageUrl!.isNotEmpty
              ? <String>[listing.imageUrl!]
              : <String>[]);

    return Publication(
      id: listing.id,
      ownerId: listing.ownerId,
      title: listing.title,
      status: listing.type == 'lost'
          ? PublicationStatus.perdu
          : PublicationStatus.trouve,
      imageUrls: images.isNotEmpty ? images : <String>[fallbackImageUrl],
      dateText: listing.date,
      description: listing.description,
      cityArea: listing.location.isNotEmpty ? listing.location : listing.city,
      likesCount: listing.likesCount,
      commentsCount: listing.commentsCount,
      likedByMe: listing.likedByMe,
      contactChat: listing.contactChat,
      contactWhatsApp: listing.contactWhatsApp,
      contactCall: listing.contactCall,
      ownerPhone: listing.ownerPhone,
      ownerName: listing.ownerName,
    );
  }

  void _appendUniquePublications(Iterable<Publication> items) {
    final existingIds = _publications.map((item) => item.id).toSet();
    for (final item in items) {
      if (existingIds.add(item.id)) {
        _publications.add(item);
      }
    }
  }

  Future<void> _loadPublications({bool reset = false}) async {
    final requestLimit = reset ? _pageSize : _loadMoreSize;

    if (reset) {
      setState(() {
        _loading = true;
        _loadingMore = false;
        _hasMore = true;
        _offset = 0;
        _error = null;
      });
    } else {
      if (_loading || _loadingMore || !_hasMore) return;
      setState(() {
        _loadingMore = true;
        _error = null;
      });
    }

    final requestId = ++_requestSerial;
    final nextOffset = reset ? 0 : _offset;

    try {
      final listings = await ApiService.instance.fetchListings(
        type: _selectedType,
        limit: requestLimit,
        offset: nextOffset,
      );
      if (!mounted || requestId != _requestSerial) return;

      final nextItems = listings.map(_mapListing).toList(growable: false);
      final receivedCount = listings.length;

      setState(() {
        if (reset) {
          _publications = [];
        }
        _appendUniquePublications(nextItems);
        _offset = nextOffset + receivedCount;
        _hasMore = receivedCount == requestLimit;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _query = query.trim().toLowerCase());
  }

  void _onFilterChanged(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    _refreshFeed();
  }

  List<Publication> get _filtered {
    if (_query.isEmpty) return _publications;

    return _publications.where((publication) {
      final haystack =
          '${publication.title} '
                  '${publication.description} '
                  '${publication.cityArea}'
              .toLowerCase();
      return haystack.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.headerBuilder != null)
          widget.headerBuilder!(_onSearchChanged),
        Row(
          children: [
            Expanded(
              child: Text(
                'Publications récentes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Actualiser',
              onPressed: _refreshFeed,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilterSegmentedControl(
          selectedIndex: _selectedIndex,
          onChanged: _onFilterChanged,
        ),
        const SizedBox(height: 14),
        _buildBody(),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_error != null && _publications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const Text(
              'Impossible de charger les annonces.',
              style: TextStyle(color: _textGray),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: _mutedGray, fontSize: 12),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _refreshFeed,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            _query.isEmpty
                ? 'Aucune annonce pour le moment.'
                : 'Aucune annonce ne correspond à votre recherche.',
            style: const TextStyle(color: _textGray),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Column(
        key: ValueKey(
          '$_selectedIndex-$_query-${_publications.length}-$_loadingMore',
        ),
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final publication = _filtered[index];
              return PublicationCard(
                publication: publication,
                purple: _purple,
                red: _red,
                green: _green,
                textGray: _textGray,
                mutedGray: _mutedGray,
              );
            },
          ),
          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}
