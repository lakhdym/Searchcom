import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'filter_segmented_control.dart';
import 'home_models.dart';
import 'publication_card.dart';

class RecentPublicationsSection extends StatefulWidget {
  const RecentPublicationsSection({super.key, this.headerBuilder});

  final HeaderBuilder? headerBuilder;

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

  List<Publication> _publications = [];
  bool _loading = true;
  String? _error;

  int _selectedIndex = 0; // 0: Tout, 1: Perdu, 2: Trouvé
  String _query = "";

  @override
  void initState() {
    super.initState();
    _loadPublications();
  }

  Future<void> _loadPublications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String? type;
      if (_selectedIndex == 1) type = 'lost';
      if (_selectedIndex == 2) type = 'found';

      final listings = await ApiService.instance.fetchListings(type: type);

      final mapped = listings.map((listing) {
        final images = listing.images.isNotEmpty
            ? listing.images
            : (listing.imageUrl != null && listing.imageUrl!.isNotEmpty
                ? <String>[listing.imageUrl!]
                : <String>[]);

        return Publication(
          id: listing.id,
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
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _publications = mapped;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _query = query.trim().toLowerCase());
  }

  List<Publication> get _filtered {
    if (_query.isEmpty) return _publications;

    return _publications.where((publication) {
      final haystack = '${publication.title} '
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
                "Publications récentes",
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
              onPressed: _loadPublications,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilterSegmentedControl(
          selectedIndex: _selectedIndex,
          onChanged: (index) {
            setState(() => _selectedIndex = index);
            _loadPublications();
          },
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

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const Text(
              "Impossible de charger les annonces.",
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
              onPressed: _loadPublications,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            "Aucune annonce pour le moment.",
            style: TextStyle(color: _textGray),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: ListView.separated(
        key: ValueKey('$_selectedIndex-$_query'),
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
    );
  }
}
