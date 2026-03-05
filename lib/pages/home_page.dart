import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'found_form_page.dart';
import 'lost_form_page.dart';
import '../widgets/top_nav_bar.dart';
import '../services/api_service.dart';

const _fallbackImageUrl =
    'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=900&q=60';

/// Home page with action cards, search bar, and recent publications list.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.showAppBar = true});

  final bool showAppBar;

  void _openLost(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LostFormPage()));
  }

  void _openFound(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FoundFormPage()));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 760;

    final lostCard = HomeActionCard(
      title: "J'ai perdu",
      subtitle:
          "Signalez un objet perdu pour augmenter vos chances de le retrouver.",
      height: 150,
      backgroundColor: const Color(0xFFFFF1F1),
      smallIconBackground: const Color(0xFFFFE4E4),
      smallIcon: Icons.heart_broken,
      smallIconColor: const Color(0xFFE53935),
      bigIcon: Icons.search,
      bigIconColor: const Color(0xFFE53935).withValues(alpha: 0.08),
      onTap: () => _openLost(context),
    );

    final foundCard = HomeActionCard(
      title: "J'ai trouvé",
      subtitle: "Aidez quelqu'un à retrouver son bien en publiant une annonce.",
      height: 150,
      backgroundColor: const Color(0xFFF1FBF5),
      smallIconBackground: const Color(0xFFDFF5E7),
      smallIcon: Icons.handshake,
      smallIconColor: const Color(0xFFF9A825),
      bigIcon: Icons.check_circle,
      bigIconColor: const Color(0xFF2E7D32).withValues(alpha: 0.08),
      onTap: () => _openFound(context),
    );

    final cardsSection = isWide
        ? Row(
            children: [
              Expanded(child: lostCard),
              const SizedBox(width: 20),
              Expanded(child: foundCard),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [lostCard, const SizedBox(height: 20), foundCard],
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: showAppBar ? const TopNavBar() : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cardsSection,
              const SizedBox(height: 20),
              // Search bar is now connected to publications section via callback
              RecentPublicationsSection(
                headerBuilder: (onSearchChanged) => Column(
                  children: [
                    SearchBarWithFilter(
                      onChanged: onSearchChanged,
                      onFilterTap: () {},
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color smallIconBackground;
  final IconData smallIcon;
  final Color smallIconColor;
  final IconData bigIcon;
  final Color bigIconColor;
  final double height;
  final VoidCallback onTap;

  const HomeActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.smallIconBackground,
    required this.smallIcon,
    required this.smallIconColor,
    required this.bigIcon,
    required this.bigIconColor,
    required this.onTap,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.black.withValues(alpha: 0.05),
        highlightColor: Colors.black.withValues(alpha: 0.02),
        child: Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.fromLTRB(24, 24, 80, 24),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: smallIconBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(smallIcon, color: smallIconColor, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5F6C7B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: -20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(bigIcon, size: 120, color: bigIconColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchBarWithFilter extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  const SearchBarWithFilter({super.key, this.onChanged, this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: "Rechercher (objet, lieu, mot-clé…)",
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onFilterTap ?? () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text(
                'Filtrer',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent publications section
// ---------------------------------------------------------------------------

enum PublicationStatus { perdu, trouve }

class Publication {
  final int id;
  final String title;
  final PublicationStatus status;
  final List<String> imageUrls;
  final String dateText;
  final String description;
  final String cityArea;
  final int likes;
  final int commentsCount;

  Publication({
    required this.id,
    required this.title,
    required this.status,
    required this.imageUrls,
    required this.dateText,
    required this.description,
    required this.cityArea,
    required this.likes,
    required this.commentsCount,
  });

  String get primaryImage =>
      imageUrls.isNotEmpty ? imageUrls.first : _fallbackImageUrl;
}

typedef HeaderBuilder = Widget Function(ValueChanged<String> onSearchChanged);

class RecentPublicationsSection extends StatefulWidget {
  const RecentPublicationsSection({super.key, this.headerBuilder});

  /// Optional: inject the SearchBar above the section and connect it to search.
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
      // ✅ fetch from API as PUBLIC (no token)
      String? type;
      if (_selectedIndex == 1) type = 'lost';
      if (_selectedIndex == 2) type = 'found';

      final listings = await ApiService.instance.fetchListings(type: type);

      final mapped = listings.map((l) {
        final images = l.images.isNotEmpty
            ? l.images
            : (l.imageUrl != null && l.imageUrl!.isNotEmpty
                  ? <String>[l.imageUrl!]
                  : <String>[]);

        return Publication(
          id: l.id,
          title: l.title,
          status: l.type == 'lost'
              ? PublicationStatus.perdu
              : PublicationStatus.trouve,
          imageUrls: images.isNotEmpty ? images : <String>[_fallbackImageUrl],
          dateText: l.date, // you can format later
          description: l.description,
          cityArea: l.location.isNotEmpty ? l.location : l.city,
          likes: 0,
          commentsCount: l.commentsCount,
        );
      }).toList();

      setState(() {
        _publications = mapped;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String q) {
    setState(() => _query = q.trim().toLowerCase());
  }

  List<Publication> get _filtered {
    final base = _publications;

    if (_query.isEmpty) return base;

    return base.where((p) {
      final hay = '${p.title} ${p.description} ${p.cityArea}'.toLowerCase();
      return hay.contains(_query);
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
          onChanged: (i) {
            setState(() => _selectedIndex = i);
            _loadPublications(); // ✅ reload by type
          },
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
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
          )
        else if (_filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                "Aucune annonce pour le moment.",
                style: TextStyle(color: _textGray),
              ),
            ),
          )
        else
          AnimatedSwitcher(
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
          ),
      ],
    );
  }
}

class FilterSegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const FilterSegmentedControl({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const pillHeight = 60.0;
    const bgColor = Color(0xFFF5F6F8);
    const textInactive = Color(0xFF6B7280);
    const textActive = Color(0xFF0F172A);
    final shadow = BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 6,
      offset: const Offset(0, 2),
    );

    const labels = ["Tout", "Perdu", "Trouvé"];

    return Container(
      height: pillHeight,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final isActive = i == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isActive ? [shadow] : [],
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isActive ? textActive : textInactive,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class PublicationCard extends StatefulWidget {
  final Publication publication;
  final Color purple;
  final Color red;
  final Color green;
  final Color textGray;
  final Color mutedGray;

  const PublicationCard({
    super.key,
    required this.publication,
    required this.purple,
    required this.red,
    required this.green,
    required this.textGray,
    required this.mutedGray,
  });

  @override
  State<PublicationCard> createState() => _PublicationCardState();
}

class _PublicationCardState extends State<PublicationCard>
    with TickerProviderStateMixin {
  bool _showComments = false;
  final TextEditingController _commentController = TextEditingController();
  late final PageController _pageController;
  int _currentImage = 0;
  List<ApiListingComment> _comments = [];
  bool _loadingComments = false;
  bool _commentsLoaded = false;
  String? _commentsError;
  bool _submittingComment = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleComments() {
    final willShow = !_showComments;
    setState(() => _showComments = willShow);
    if (willShow && !_commentsLoaded && !_loadingComments) {
      _loadComments();
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      _loadingComments = true;
      _commentsError = null;
    });

    try {
      final comments = await ApiService.instance.fetchComments(
        widget.publication.id,
      );
      if (mounted) {
        setState(() {
          _comments = comments;
          _commentsLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commentsError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingComments = false;
        });
      }
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _submittingComment) return;

    setState(() {
      _submittingComment = true;
      _commentsError = null;
    });

    try {
      final newComment = await ApiService.instance.addComment(
        listingId: widget.publication.id,
        content: text,
      );
      if (!mounted) return;
      setState(() {
        _comments.insert(0, newComment);
        _commentsLoaded = true;
        _showComments = true;
      });
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        setState(() {
          _commentsError = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'envoyer le commentaire")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingComment = false;
        });
      }
    }
  }

  String _formatRelative(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "A l'instant";
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Il y a ${diff.inHours} h";
    if (diff.inDays < 7) return "Il y a ${diff.inDays} j";
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "${date.year}-$m-$d";
  }

  @override
  Widget build(BuildContext context) {
    final publication = widget.publication;
    final badgeColor = publication.status == PublicationStatus.perdu
        ? widget.red
        : widget.green;
    final badgeLabel = publication.status == PublicationStatus.perdu
        ? "PERDU"
        : "TROUVÉ";
    final radius = BorderRadius.circular(16);
    final commentCount = _commentsLoaded
        ? _comments.length
        : publication.commentsCount;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 185,
                width: double.infinity,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentImage = i),
                  itemCount: publication.imageUrls.length,
                  itemBuilder: (_, index) {
                    final img = publication.imageUrls[index];
                    return Image.network(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (publication.imageUrls.length > 1)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(publication.imageUrls.length, (i) {
                      final active = i == _currentImage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 8,
                        width: active ? 16 : 8,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Builder(
                  builder: (btnContext) => GestureDetector(
                    onTap: () => _showPublicationMenu(btnContext),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.more_horiz,
                        size: 18,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        publication.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          publication.dateText,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.mutedGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  publication.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.textGray,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.place, size: 16, color: widget.purple),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        publication.cityArea,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.textGray,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_border, size: 18, color: widget.red),
                    const SizedBox(width: 4),
                    Text(
                      "${publication.likes}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: _toggleComments,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mode_comment_outlined,
                        size: 18,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$commentCount",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Builder(
                  builder: (buttonContext) {
                    return Material(
                      color: widget.purple,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _showConversationMenu(buttonContext),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _showComments
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        if (_loadingComments)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        else if (_commentsError != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Impossible de charger les commentaires.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _commentsError!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF),
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              TextButton(
                                onPressed: _loadComments,
                                child: const Text("Réessayer"),
                              ),
                            ],
                          )
                        else if (_comments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              "Aucun commentaire",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          )
                        else
                          ..._comments.map((c) {
                            final author =
                                c.fullName ?? "Utilisateur #${c.userId}";
                            final initial = author.isNotEmpty ? author[0] : '?';
                            final timeLabel = _formatRelative(c.createdAt);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: const Color(0xFFE5E7EB),
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              author,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                            Text(
                                              timeLabel,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          c.content,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  minLines: 1,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText: "Écrire un commentaire…",
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              _submittingComment
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        Icons.send,
                                        color: widget.purple,
                                        size: 20,
                                      ),
                                      onPressed: _addComment,
                                      splashRadius: 20,
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showConversationMenu(BuildContext context) async {
    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      button.localToGlobal(Offset.zero, ancestor: overlay) & button.size,
      Offset.zero & overlay.size,
    );

    await showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: [
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: _MenuRow(
            bg: const Color(0xFFE8F8EF),
            icon: Icons.call,
            iconColor: const Color(0xFF34C759),
            label: "WhatsApp",
          ),
          onTap: () => debugPrint("WhatsApp"),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: _MenuRow(
            bg: const Color(0xFFF1E9FF),
            icon: Icons.chat_bubble_outline,
            iconColor: widget.purple,
            label: "Chat interne",
          ),
          onTap: () => debugPrint("Chat interne"),
        ),
      ],
    );
  }

  Future<void> _showPublicationMenu(BuildContext context) async {
    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    const double menuWidth = 220;
    const double offsetX = 8;

    Offset desiredTopLeft = button.localToGlobal(
      Offset(button.size.width + offsetX, 0),
      ancestor: overlay,
    );

    if (desiredTopLeft.dx + menuWidth > overlay.size.width) {
      desiredTopLeft = button.localToGlobal(
        Offset(-menuWidth - offsetX, 0),
        ancestor: overlay,
      );
      if (desiredTopLeft.dx < 8) {
        desiredTopLeft = Offset(8, desiredTopLeft.dy);
      }
    }

    final position = RelativeRect.fromRect(
      Rect.fromLTWH(
        desiredTopLeft.dx,
        desiredTopLeft.dy,
        menuWidth,
        button.size.height,
      ),
      Offset.zero & overlay.size,
    );

    await showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: [
        _menuItem(
          icon: Icons.link,
          label: "Copier le lien",
          onTap: () => _copyLink(context),
        ),
        _menuItem(
          icon: Icons.share,
          label: "Partager",
          onTap: () => debugPrint("Partager"),
        ),
        _menuItem(
          icon: Icons.flag,
          label: "Signaler",
          iconColor: Colors.red,
          textColor: Colors.red,
          onTap: () => _confirmReport(context),
        ),
      ],
    );
  }

  PopupMenuItem _menuItem({
    required IconData icon,
    required String label,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return PopupMenuItem(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor ?? const Color(0xFF4B5563)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor ?? const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReport(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Signaler cette publication ?"),
        content: const Text(
          "Voulez-vous vraiment signaler cette publication ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Signaler", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      debugPrint("Signaler");
    }
  }

  void _copyLink(BuildContext context) {
    final link =
        "https://italents.ma/p/${Uri.encodeComponent(widget.publication.title)}";
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Lien copié")));
  }
}

class _MenuRow extends StatelessWidget {
  final Color bg;
  final Color iconColor;
  final IconData icon;
  final String label;

  const _MenuRow({
    required this.bg,
    required this.iconColor,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
