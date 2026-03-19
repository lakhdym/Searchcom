// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'found_form_page.dart';
import 'login_page.dart';
import '../features/chat/pages/conversations_page.dart';
import '../features/chat/pages/chat_detail_page.dart';
import '../features/chat/models/chat_models.dart';
import '../widgets/top_nav_bar.dart';
import '../services/auth_local_storage.dart';
import '../services/api_service.dart';

const _fallbackImageUrl =
    'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=900&q=60';

/// Home page with action cards, search bar, and recent publications list.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.showAppBar = true});

  final bool showAppBar;

  void _openLost(BuildContext context) {
    _guardAuthThen(
      context,
      onAllowed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FoundFormPage(type: "lost"))),
      title: "Connexion requise",
      message: "Vous devez vous connecter pour publier une annonce perdue.",
    );
  }

  void _openFound(BuildContext context) {
    _guardAuthThen(
      context,
      onAllowed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FoundFormPage(type: "found"))),
      title: "Connexion requise",
      message: "Vous devez vous connecter pour publier une annonce.",
    );
  }

  void _guardAuthThen(
    BuildContext context, {
    required VoidCallback onAllowed,
    required String title,
    required String message,
  }) async {
    final storedToken = await AuthLocalStorage.instance.getToken();
    debugPrint(
      '[GuardLostFound] tokenPresent=${storedToken != null && storedToken.isNotEmpty}',
    );

    if (storedToken != null && storedToken.isNotEmpty) {
      ApiService.instance.setToken(storedToken);
      onAllowed();
      return;
    }

    final navigator = Navigator.of(context);

    final goLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Se connecter"),
          ),
        ],
      ),
    );

    if (!navigator.mounted) return;

    if (goLogin == true) {
      navigator.push(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  /*
  Future<void> _guardAuthThen(
    BuildContext context, {
    required VoidCallback onAllowed,
    required String title,
    required String message,
  }) async {
    final token = await AuthLocalStorage.instance.getToken();
    final isLoggedIn = token != null && token.isNotEmpty;

    debugPrint("TOKEN = $token");
    debugPrint("isLoggedIn = $isLoggedIn");

    if (isLoggedIn) {
      onAllowed();
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text("Se connecter"),
          ),
        ],
      ),
    );
  }
*/
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
  final int ownerId;
  final String? ownerName;
  final String title;
  final PublicationStatus status;
  final List<String> imageUrls;
  final String dateText;
  final String description;
  final String cityArea;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;
  final bool contactChat;
  final bool contactWhatsApp;
  final bool contactCall;
  final String? ownerPhone;

  Publication({
    required this.id,
    required this.ownerId,
    this.ownerName,
    required this.title,
    required this.status,
    required this.imageUrls,
    required this.dateText,
    required this.description,
    required this.cityArea,
    required this.likesCount,
    required this.commentsCount,
    required this.likedByMe,
    required this.contactChat,
    required this.contactWhatsApp,
    required this.contactCall,
    required this.ownerPhone,
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
          ownerId: l.ownerId,
          ownerName: l.ownerName,
          title: l.title,
          status: l.type == 'lost'
              ? PublicationStatus.perdu
              : PublicationStatus.trouve,
          imageUrls: images.isNotEmpty ? images : <String>[_fallbackImageUrl],
          dateText: l.date, // you can format later
          description: l.description,
          cityArea: l.location.isNotEmpty ? l.location : l.city,
          likesCount: l.likesCount,
          commentsCount: l.commentsCount,
          likedByMe: l.likedByMe,
          contactChat: l.contactChat,
          contactWhatsApp: l.contactWhatsApp,
          contactCall: l.contactCall,
          ownerPhone: l.ownerPhone,
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
  List<ApiListingLike> _likes = [];
  bool _likesLoaded = false;
  bool _likesLoading = false;
  String? _likesError;
  bool _submittingComment = false;
  bool _liked = false;
  int _likesCount = 0;
  bool _likeBusy = false;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _liked = widget.publication.likedByMe;
    _likesCount = widget.publication.likesCount;
    _loadOwner();
  }

  Future<void> _loadOwner() async {
    final me = await AuthLocalStorage.instance.getUser();
    if (!mounted) return;
    setState(() {
      _isOwner = (me != null && me.id == widget.publication.ownerId);
    });
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

  Future<void> _loadLikes() async {
    setState(() {
      _likesLoading = true;
      _likesError = null;
    });

    try {
      final likes = await ApiService.instance.fetchLikes(widget.publication.id);
      if (mounted) {
        setState(() {
          _likes = likes;
          _likesLoaded = true;
          _likesCount = likes.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _likesError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _likesLoading = false;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_likeBusy) return;
    if (!ApiService.instance.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Connectez-vous pour liker cette annonce"),
        ),
      );
      return;
    }

    setState(() => _likeBusy = true);

    try {
      final result = await ApiService.instance.toggleLike(
        widget.publication.id,
      );
      if (!mounted) return;
      setState(() {
        _liked = result.liked;
        _likesCount = result.likesCount;
        // invalide la liste pour forcer un refresh propre si besoin
        _likesLoaded = false;
        _likes = [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible de mettre \u00e0 jour le like"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  Future<void> _openLikes() async {
    if (!_likesLoaded && !_likesLoading) {
      await _loadLikes();
    }
    if (!mounted) return;

    if (_likesError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de charger les likes")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) {
        if (_likesLoading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (_likes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Aucun like pour l'instant.",
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _likes.length,
          separatorBuilder: (_, index) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final like = _likes[index];
            final name = like.fullName.isNotEmpty
                ? like.fullName
                : ((like.userId != null && like.userId != 0)
                      ? "Utilisateur #${like.userId}"
                      : "Utilisateur");
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE5E7EB),
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              subtitle: Text(
                _formatRelative(like.createdAt),
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _submittingComment) return;

    if (!ApiService.instance.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connectez-vous pour commenter")),
      );
      return;
    }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Commentaire ajouté")));
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

  Future<void> _openFullDetails() async {
    if (!_commentsLoaded && !_loadingComments) {
      await _loadComments();
    }
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> refreshComments() async {
              await _loadComments();
              setSheetState(() {});
            }

            Future<void> sendComment() async {
              await _addComment();
              setSheetState(() {});
            }

            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            final publication = widget.publication;
            return Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.9,
                minChildSize: 0.6,
                maxChildSize: 0.95,
                builder: (ctx, controller) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    publication.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: publication.status ==
                                            PublicationStatus.perdu
                                        ? widget.red
                                        : widget.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    publication.status ==
                                            PublicationStatus.perdu
                                        ? "PERDU"
                                        : "TROUVÉ",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.place, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    publication.cityArea,
                                    style: TextStyle(
                                      color: widget.textGray,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.calendar_today_outlined,
                                    size: 14, color: Color(0xFF9CA3AF)),
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
                            const SizedBox(height: 12),
                            if (publication.imageUrls.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  publication.imageUrls.first,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 180,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.image, size: 48),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 14),
                            Text(
                              publication.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.textGray,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                const Text(
                                  "Commentaires",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (_commentsLoaded)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5E7EB),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "${_comments.length}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF4B5563),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 18),
                                  onPressed: refreshComments,
                                ),
                              ],
                            ),
                            if (_loadingComments)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
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
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  "Erreur: $_commentsError",
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            else if (_comments.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  "Aucun commentaire pour l'instant.",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280)),
                                ),
                              )
                            else
                              ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: _comments.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, index) {
                                  final c = _comments[index];
                                  final author = c.fullName.isNotEmpty
                                      ? c.fullName
                                      : ((c.userId != null && c.userId != 0)
                                            ? "Utilisateur #${c.userId}"
                                            : "Utilisateur");
                                  final timeLabel =
                                      _formatRelative(c.createdAt);
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          const Color(0xFFE5E7EB),
                                      child: Text(
                                        author.isNotEmpty ? author[0] : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      author,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text(
                                          timeLabel,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          c.content,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  minLines: 1,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText: "Ajouter un commentaire...",
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _submittingComment
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        Icons.send,
                                        color: widget.purple,
                                        size: 20,
                                      ),
                                      onPressed: sendComment,
                                      splashRadius: 20,
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
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
    final likesCount = _likesCount;
    final commentCount = _commentsLoaded
        ? _comments.length
        : publication.commentsCount;
    final hasPhone = (publication.ownerPhone?.trim().isNotEmpty ?? false);
    final isOwner = _isOwner;
    final hasContactOptions = (!isOwner && publication.contactChat) ||
        (publication.contactWhatsApp && hasPhone) ||
        (publication.contactCall && hasPhone);
    final bool longDescription = publication.description.length > 140;

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
                if (longDescription)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _openFullDetails,
                      child: const Text("Lire la suite"),
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
                if (hasContactOptions) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (publication.contactWhatsApp && hasPhone)
                        _contactChip(
                          icon: Icons.chat_bubble,
                          label: "WhatsApp",
                          color: const Color(0xFF25D366),
                          bg: const Color(0xFFE8F8EF),
                          onTap: () => _launchWhatsApp(publication.ownerPhone ?? ''),
                        ),
                      if (publication.contactCall && hasPhone)
                        _contactChip(
                          icon: Icons.call,
                          label: "Appeler",
                          color: const Color(0xFF2563EB),
                          bg: const Color(0xFFE8ECFF),
                          onTap: () => _launchCall(publication.ownerPhone ?? ''),
                        ),
                      if (publication.contactChat)
                        _contactChip(
                          icon: Icons.chat_bubble_outline,
                          label: "Chat",
                          color: widget.purple,
                          bg: const Color(0xFFF1E9FF),
                          onTap: _openInternalChat,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  onLongPress: _openLikes,
                  child: Row(
                    children: [
                      if (_likeBusy)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          _liked ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: widget.red,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        "$likesCount",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
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
                if (hasContactOptions)
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
                            final author = c.fullName.isNotEmpty
                                ? c.fullName
                                : ((c.userId != null && c.userId != 0)
                                      ? "Utilisateur #${c.userId}"
                                      : "Utilisateur");
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
    final pub = widget.publication;
    final phone = pub.ownerPhone?.trim() ?? '';
    final hasPhone = phone.isNotEmpty;

    final items = <PopupMenuEntry<String>>[];
    if (pub.contactWhatsApp && hasPhone) {
      items.add(
        PopupMenuItem(
          value: 'wa',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: _MenuRow(
            bg: const Color(0xFFE8F8EF),
            icon: Icons.chat_bubble,
            iconColor: const Color(0xFF25D366),
            label: "WhatsApp",
          ),
        ),
      );
    }
    if (pub.contactCall && hasPhone) {
      items.add(
        PopupMenuItem(
          value: 'call',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: _MenuRow(
            bg: const Color(0xFFE8ECFF),
            icon: Icons.call,
            iconColor: const Color(0xFF2563EB),
            label: "Appeler",
          ),
        ),
      );
    }
    if (pub.contactChat && !_isOwner) {
      items.add(
        PopupMenuItem(
          value: 'chat',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: _MenuRow(
            bg: const Color(0xFFF1E9FF),
            icon: Icons.chat_bubble_outline,
            iconColor: widget.purple,
            label: "Chat interne",
          ),
        ),
      );
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucun moyen de contact disponible")),
      );
      return;
    }

    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      button.localToGlobal(Offset.zero, ancestor: overlay) & button.size,
      Offset.zero & overlay.size,
    );

    final choice = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: items,
    );

    if (choice == null) return;
    if (choice == 'wa') {
      await _launchWhatsApp(phone);
    } else if (choice == 'call') {
      await _launchCall(phone);
    } else if (choice == 'chat') {
      _openInternalChat();
    }
  }

  String? _normalizedPhone(String raw) {
    if (raw.isEmpty) return null;
    var cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('00')) {
      cleaned = cleaned.substring(2);
    }
    return cleaned.isEmpty ? null : cleaned;
  }

  Future<void> _launchWhatsApp(String rawPhone) async {
    final normalized = _normalizedPhone(rawPhone);
    if (normalized == null) {
      _showSnack("Numéro WhatsApp indisponible");
      return;
    }
    final uri = Uri.parse('https://wa.me/$normalized');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        _showSnack("Impossible d'ouvrir WhatsApp");
      }
    } catch (_) {
      if (mounted) _showSnack("Impossible d'ouvrir WhatsApp");
    }
  }

  Future<void> _launchCall(String rawPhone) async {
    final normalized = _normalizedPhone(rawPhone);
    if (normalized == null) {
      _showSnack("Numéro d'appel indisponible");
      return;
    }
    final uri = Uri(scheme: 'tel', path: normalized);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        _showSnack("Impossible d'ouvrir le composeur");
      }
    } catch (_) {
      if (mounted) _showSnack("Impossible d'ouvrir le composeur");
    }
  }

  Future<void> _openInternalChat() async {
    final user = await AuthLocalStorage.instance.getUser();
    if (!mounted) return;
    if (user == null) {
      _showSnack("Vous devez vous connecter pour discuter");
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    if (widget.publication.ownerId == user.id) {
      _showSnack("Vous ne pouvez pas chatter avec votre propre annonce");
      return;
    }
    try {
      final convId = await ApiService.instance
          .getOrCreateConversation(listingId: widget.publication.id, userId: user.id);

      final otherUser = ChatUser(
        id: widget.publication.ownerId.toString(),
        name: widget.publication.ownerName ?? 'Utilisateur',
        avatarColor: Colors.teal,
      );
      final placeholderLast = ChatMessage(
        id: 'init_$convId',
        conversationId: convId.toString(),
        text: '',
        isMe: false,
        time: DateTime.now(),
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            conversation: ChatConversation(
              id: convId.toString(),
              user: otherUser,
              unreadCount: 0,
              lastMessage: placeholderLast,
            ),
          ),
        ),
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('propre annonce')) {
        _showSnack("Vous ne pouvez pas chatter avec votre propre annonce");
      } else {
        _showSnack('Erreur: $msg');
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _contactChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    Color? bg,
  }) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16, color: color ?? widget.purple),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      backgroundColor: bg ?? Colors.grey.shade100,
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          onTap: _shareListing,
        ),
        _menuItem(
          icon: Icons.flag,
          label: "Signaler",
          iconColor: Colors.red,
          textColor: Colors.red,
          onTap: _reportListing,
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

  String _buildListingShareUrl() {
    const base = 'https://italents.ma/app/listing';
    return '$base/${widget.publication.id}';
  }

  Future<void> _shareListing() async {
    final url = _buildListingShareUrl();
    final buffer = StringBuffer()
      ..write("Regarde cette annonce : ${widget.publication.title}");
    if (widget.publication.cityArea.isNotEmpty) {
      buffer.write(" à ${widget.publication.cityArea}");
    }
    buffer.write("\n$url");
    await Share.share(buffer.toString());
  }

  Future<void> _reportListing() async {
    final token = await AuthLocalStorage.instance.getToken();
    if (token == null || token.isEmpty) {
      final goLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Connexion requise"),
          content: const Text(
              "Vous devez vous connecter pour signaler une annonce."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("Se connecter"),
            ),
          ],
        ),
      );
      if (goLogin == true && mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      }
      return;
    }

    ApiService.instance.setToken(token);
    final reasons = ['spam', 'scam', 'abuse', 'illegal', 'other'];
    String selected = reasons.first;
    final detailsCtrl = TextEditingController();
    bool sending = false;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Signaler l'annonce",
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...reasons.map(
                    (r) => RadioListTile<String>(
                      dense: true,
                      value: r,
                      groupValue: selected,
                      onChanged: (v) => setSheetState(() => selected = v ?? selected),
                      title: Text(r),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: detailsCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Détails (optionnel)",
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      TextButton(
                        onPressed: sending ? null : () => Navigator.of(ctx).pop(),
                        child: const Text("Annuler"),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: sending
                            ? null
                            : () async {
                                setSheetState(() => sending = true);
                                try {
                                  await ApiService.instance.reportListing(
                                    listingId: widget.publication.id,
                                    reason: selected,
                                    details: detailsCtrl.text,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Signalement envoyé")),
                                    );
                                  }
                                  Navigator.of(ctx).pop(true);
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Erreur: $e")),
                                    );
                                  }
                                  setSheetState(() => sending = false);
                                }
                              },
                        child: sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text("Envoyer"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    detailsCtrl.dispose();
  }

  void _copyLink(BuildContext context) {
    final link = _buildListingShareUrl();
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
