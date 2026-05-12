import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_messages.dart';
import '../../core/errors/app_error_mapper.dart';
import '../../core/navigation/app_route_observer.dart';
import '../../services/l10n_helper.dart';
import 'filter_segmented_control.dart';
import 'home_listings_api.dart';
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

class _RecentPublicationsSectionState extends State<RecentPublicationsSection>
    with WidgetsBindingObserver, RouteAware {
  static const _red = Color(0xFFFF3B30);
  static const _green = Color(0xFF34C759);
  static const _mutedGray = Color(0xFF9CA3AF);
  static const _pageSize = 5;
  static const _loadMoreSize = 5;
  static const _prefetchThreshold = 180.0;
  static const _backgroundRefreshInterval = Duration(seconds: 6);

  List<Publication> _publications = [];
  bool _loading = true;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;
  int _requestSerial = 0;
  Timer? _backgroundRefreshTimer;
  AppLifecycleState? _appLifecycleState;
  ModalRoute<dynamic>? _route;
  bool _isCurrentRoute = true;

  int _selectedIndex = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.scrollController?.addListener(_handleScroll);
    widget.refreshListenable?.addListener(_handleExternalRefresh);
    _startBackgroundRefresh();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextRoute = ModalRoute.of(context);
    if (_route == nextRoute) return;

    if (_route != null) {
      appRouteObserver.unsubscribe(this);
    }

    _route = nextRoute;
    if (nextRoute != null) {
      appRouteObserver.subscribe(this, nextRoute);
      _isCurrentRoute = nextRoute.isCurrent;
    } else {
      _isCurrentRoute = true;
    }
  }

  @override
  void dispose() {
    _backgroundRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_route != null) {
      appRouteObserver.unsubscribe(this);
    }
    widget.scrollController?.removeListener(_handleScroll);
    widget.refreshListenable?.removeListener(_handleExternalRefresh);
    super.dispose();
  }

  bool get _isPageVisible {
    final isAppResumed =
        _appLifecycleState == null ||
        _appLifecycleState == AppLifecycleState.resumed;
    return _isCurrentRoute && isAppResumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
  }

  @override
  void didPush() {
    _isCurrentRoute = true;
  }

  @override
  void didPopNext() {
    _isCurrentRoute = true;
  }

  @override
  void didPushNext() {
    _isCurrentRoute = false;
  }

  @override
  void didPop() {
    _isCurrentRoute = false;
  }

  void _startBackgroundRefresh() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = Timer.periodic(_backgroundRefreshInterval, (_) {
      if (!mounted || !_isPageVisible || _loading || _refreshing || _loadingMore) {
        return;
      }
      _refreshFeed(silent: _publications.isNotEmpty);
    });
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

  void _scheduleLoadMoreIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loading || _loadingMore || !_hasMore) return;

      final controller = widget.scrollController;
      if (controller == null || !controller.hasClients) return;

      final position = controller.position;
      final shouldLoadMore =
          position.maxScrollExtent <= _prefetchThreshold ||
          position.extentAfter <= _prefetchThreshold;

      if (shouldLoadMore) {
        _loadPublications();
      }
    });
  }

  void _handleExternalRefresh() {
    _refreshFeed(silent: _publications.isNotEmpty);
  }

  Future<void> _refreshFeed({bool silent = false}) async {
    if (_refreshing || _loadingMore) return;
    if (_loading && _publications.isNotEmpty) return;
    await _loadPublications(reset: true, silent: silent);
  }

  Publication _mapListing(HomeListingItem listing) {
    final images = listing.images.isNotEmpty
        ? listing.images
        : (listing.imageUrl != null && listing.imageUrl!.isNotEmpty
              ? <String>[listing.imageUrl!]
              : <String>[]);

    return Publication(
      id: listing.id,
      ownerId: listing.ownerId ?? 0,
      title: listing.title,
      status: listing.type == 'lost'
          ? PublicationStatus.perdu
          : PublicationStatus.trouve,
      imageUrls: images.isNotEmpty ? images : <String>[fallbackImageUrl],
      dateText: listing.date,
      eventDate: listing.eventDate ?? '',
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

  List<Publication> _mergeRefreshedPublications(
    List<Publication> refreshedItems,
  ) {
    final refreshedIds = refreshedItems.map((item) => item.id).toSet();
    return <Publication>[
      ...refreshedItems,
      ..._publications.where((item) => !refreshedIds.contains(item.id)),
    ];
  }

  void _updatePublication(Publication updatedPublication) {
    final index = _publications.indexWhere(
      (item) => item.id == updatedPublication.id,
    );
    if (index < 0) return;

    setState(() {
      _publications[index] = _publications[index].copyWith(
        likesCount: updatedPublication.likesCount,
        commentsCount: updatedPublication.commentsCount,
        likedByMe: updatedPublication.likedByMe,
      );
    });
  }

  Future<void> _loadPublications({bool reset = false, bool silent = false}) async {
    final requestLimit = reset ? _pageSize : _loadMoreSize;
    final canSilentRefresh = reset && silent && _publications.isNotEmpty;

    if (reset) {
      setState(() {
        _loading = !canSilentRefresh;
        _refreshing = canSilentRefresh;
        _loadingMore = false;
        if (!canSilentRefresh) {
          _hasMore = true;
          _offset = 0;
        }
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
      final listings = await HomeListingsApi.instance.fetchListings(
        type: _selectedType,
        limit: requestLimit,
        offset: nextOffset,
      );
      if (!mounted || requestId != _requestSerial) return;

      final nextItems = listings.map(_mapListing).toList(growable: false);
      final receivedCount = listings.length;

      setState(() {
        if (reset) {
          if (canSilentRefresh) {
            _publications = _mergeRefreshedPublications(nextItems);
            _offset = _publications.length;
          } else {
            _publications = nextItems;
            _offset = nextOffset + receivedCount;
            _hasMore = receivedCount == requestLimit;
          }
        } else {
          _appendUniquePublications(nextItems);
          _offset = nextOffset + receivedCount;
          _hasMore = receivedCount == requestLimit;
        }
        _loading = false;
        _refreshing = false;
        _loadingMore = false;
      });
      _scheduleLoadMoreIfNeeded();
    } catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _error = AppErrorMapper.message(
          e,
          fallbackMessage: AppMessages.listingsLoadError(),
        );
        _loading = false;
        _refreshing = false;
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
          '${publication.title} ${publication.description} ${publication.cityArea}'
              .toLowerCase();
      return haystack.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.headerBuilder != null)
          widget.headerBuilder!(_onSearchChanged),
        Row(
          children: [
            Expanded(
              child: Text(
                t('recent_publications'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? scheme.surfaceContainer.withValues(alpha: 0.82)
                    : scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: IconButton(
                tooltip: t('refresh'),
                onPressed: _loading
                    ? null
                    : () => _refreshFeed(silent: _publications.isNotEmpty),
                icon: const Icon(Icons.refresh),
                color: scheme.onSurfaceVariant,
              ),
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purple = scheme.primary;
    final textGray = scheme.onSurfaceVariant;
    final mutedGray = isDark
        ? scheme.onSurfaceVariant.withValues(alpha: 0.72)
        : _mutedGray;
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
            Text(
              _error!,
              style: TextStyle(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _refreshFeed, child: Text(t('retry'))),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            _query.isEmpty ? t('no_listings_yet') : t('no_search_results'),
            style: TextStyle(color: scheme.onSurfaceVariant),
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
          Column(
            children: [
              for (var index = 0; index < _filtered.length; index++) ...[
                PublicationCard(
                  key: ValueKey<int>(_filtered[index].id),
                  publication: _filtered[index],
                  purple: purple,
                  red: _red,
                  green: _green,
                  textGray: textGray,
                  mutedGray: mutedGray,
                  onPublicationChanged: _updatePublication,
                ),
                if (index < _filtered.length - 1) const SizedBox(height: 14),
              ],
            ],
          ),
          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (!_hasMore && _publications.isNotEmpty && _query.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  t('viewed_all_listings'),
                  style: TextStyle(
                    fontSize: 13,
                    color: mutedGray,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
