import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'found_form_page.dart';
import 'lost_form_page.dart';

/// Home page with action cards, search bar, and recent publications grid.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openLost(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LostFormPage()),
    );
  }

  void _openFound(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FoundFormPage()),
    );
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
      bigIconColor: const Color(0xFFE53935).withOpacity(0.08),
      onTap: () => _openLost(context),
    );

    final foundCard = HomeActionCard(
      title: "J'ai trouvé",
      subtitle:
          "Aidez quelqu'un à retrouver son bien en publiant une annonce.",
      height: 150,
      backgroundColor: const Color(0xFFF1FBF5),
      smallIconBackground: const Color(0xFFDFF5E7),
      smallIcon: Icons.handshake,
      smallIconColor: const Color(0xFFF9A825),
      bigIcon: Icons.check_circle,
      bigIconColor: const Color(0xFF2E7D32).withOpacity(0.08),
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
            children: [
              lostCard,
              const SizedBox(height: 20),
              foundCard,
            ],
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cardsSection,
              const SizedBox(height: 20),
              const SearchBarWithFilter(),
              const SizedBox(height: 24),
              const RecentPublicationsSection(),
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
        splashColor: Colors.black.withOpacity(0.05),
        highlightColor: Colors.black.withOpacity(0.02),
        child: Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.fromLTRB(24, 24, 80, 24),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
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
                    child: Icon(
                      smallIcon,
                      color: smallIconColor,
                      size: 22,
                    ),
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
                  child: Icon(
                    bigIcon,
                    size: 120,
                    color: bigIconColor,
                  ),
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
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
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                // contentPadding: EdgeInsets.zero,
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

class RecentPublicationsSection extends StatefulWidget {
  const RecentPublicationsSection({super.key});

  @override
  State<RecentPublicationsSection> createState() =>
      _RecentPublicationsSectionState();
}

enum PublicationStatus { perdu, trouve }

class Publication {
  final String title;
  final PublicationStatus status;
  final String imageUrl;
  final String dateText;
  final String description;
  final String cityArea;
  final int likes;
  final int comments;

  const Publication({
    required this.title,
    required this.status,
    required this.imageUrl,
    required this.dateText,
    required this.description,
    required this.cityArea,
    required this.likes,
    required this.comments,
  });
}

class _RecentPublicationsSectionState extends State<RecentPublicationsSection> {
  static const _purple = Color(0xFF6C2BFF);
  static const _red = Color(0xFFFF3B30);
  static const _green = Color(0xFF34C759);
  static const _textGray = Color(0xFF6B7280);
  static const _mutedGray = Color(0xFF9CA3AF);

  final List<Publication> _publications = const [
    Publication(
      title: "Portefeuille en cuir marron",
      status: PublicationStatus.perdu,
      imageUrl:
          "https://images.unsplash.com/photo-1542293787938-4d273c36b05d?auto=format&fit=crop&w=900&q=60",
      dateText: "Aujourd’hui, 09:30",
      description: "Perdu près de la gare, contient carte nationale et permis.",
      cityArea: "Casablanca, Gare",
      likes: 12,
      comments: 4,
    ),
    Publication(
      title: "Clés de voiture BMW",
      status: PublicationStatus.trouve,
      imageUrl:
          "https://images.unsplash.com/photo-1503736334956-4c8f8e92946d?auto=format&fit=crop&w=900&q=60",
      dateText: "Aujourd’hui, 11:10",
      description: "Trousseau avec badge bleu trouvé devant café Venezia.",
      cityArea: "Rabat, Agdal",
      likes: 8,
      comments: 3,
    ),
    Publication(
      title: "Chien Golden Retriever",
      status: PublicationStatus.perdu,
      imageUrl:
          "https://images.unsplash.com/photo-1507146426996-ef05306b995a?auto=format&fit=crop&w=900&q=60",
      dateText: "Hier, 18:45",
      description: "Répond au nom Simba, collier rouge. Vu pour la dernière fois au parc.",
      cityArea: "Marrakech, Guéliz",
      likes: 30,
      comments: 12,
    ),
    Publication(
      title: "iPhone 13 rouge",
      status: PublicationStatus.trouve,
      imageUrl:
          "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=900&q=60",
      dateText: "2 Fév, 14:00",
      description: "Téléphone trouvé dans le tram, écran intact, coque rouge.",
      cityArea: "Tanger, Centre",
      likes: 19,
      comments: 6,
    ),
  ];

  int _selectedIndex = 0; // 0: Tout, 1: Perdu, 2: Trouvé

  List<Publication> get _filtered {
    if (_selectedIndex == 1) {
      return _publications
          .where((p) => p.status == PublicationStatus.perdu)
          .toList();
    }
    if (_selectedIndex == 2) {
      return _publications
          .where((p) => p.status == PublicationStatus.trouve)
          .toList();
    }
    return _publications;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8), // léger offset haut
            Text(
              "Publications récentes",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: FilterSegmentedControl(
                selectedIndex: _selectedIndex,
                onChanged: (i) => setState(() => _selectedIndex = i),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: ListView.separated(
            key: ValueKey(_selectedIndex),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
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
    const textInactive = Color(0xFF6B7280); // plus contrasté
    const textActive = Color(0xFF0F172A);
    final shadow = BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 6,
      offset: const Offset(0, 2),
    );

    List<String> labels = const ["Tout", "Perdu", "Trouvé"];
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
  late List<Comment> _comments;

  @override
  void initState() {
    super.initState();
    _comments = [
      const Comment(
        name: "Imane",
        text: "Je crois l’avoir vu près de la sortie côté tram.",
        time: "Il y a 5 min",
      ),
      const Comment(
        name: "Youssef",
        text: "Vérifie au bureau info de la gare, ils gardent souvent les objets.",
        time: "Il y a 12 min",
      ),
    ];
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleComments() {
    setState(() => _showComments = !_showComments);
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.add(Comment(
        name: "Moi",
        text: text,
        time: "Maintenant",
      ));
      _commentController.clear();
      _showComments = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final publication = widget.publication;
    final badgeColor = publication.status == PublicationStatus.perdu ? widget.red : widget.green;
    final badgeLabel = publication.status == PublicationStatus.perdu ? "PERDU" : "TROUVÉ";
    final radius = BorderRadius.circular(16);

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
                child: Image.network(
                  publication.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, size: 48, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.more_horiz,
                          size: 18, color: Color(0xFF4B5563)),
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
                      const Icon(Icons.mode_comment_outlined,
                          size: 18, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Text(
                        "${publication.comments}",
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
                          child: Icon(Icons.chat_bubble_outline,
                              color: Colors.white, size: 18),
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
                        if (_comments.isEmpty)
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
                          ..._comments.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: const Color(0xFFE5E7EB),
                                    child: Text(
                                      c.name.isNotEmpty ? c.name[0] : '?',
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              c.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                            Text(
                                              c.time,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          c.text,
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
                            ),
                          ),
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
                              IconButton(
                                icon: Icon(Icons.send, color: widget.purple, size: 20),
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
          onTap: () => print("WhatsApp"),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: _MenuRow(
            bg: const Color(0xFFF1E9FF),
            icon: Icons.chat_bubble_outline,
            iconColor: widget.purple,
            label: "Chat interne",
          ),
          onTap: () => print("Chat interne"),
        ),
      ],
    );
  }

  Future<void> _showPublicationMenu(BuildContext context) async {
    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    const double menuWidth = 220;
    const double offsetX = 8;

    // position souhaitée à droite
    Offset desiredTopLeft =
        button.localToGlobal(Offset(button.size.width + offsetX, 0), ancestor: overlay);

    // si dépasse à droite, placer à gauche du bouton
    if (desiredTopLeft.dx + menuWidth > overlay.size.width) {
      desiredTopLeft = button.localToGlobal(
        Offset(-menuWidth - offsetX, 0),
        ancestor: overlay,
      );
      // si encore négatif, clamp à 8px
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
          onTap: () => print("Partager"),
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

  Future<void> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Supprimer la publication"),
          content: const Text("Êtes-vous sûr de vouloir supprimer cette publication ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                "Oui, supprimer",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    if (result == true) {
      print("Supprimer la publication");
    }
  }

  Future<void> _confirmReport(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Signaler cette publication ?"),
        content: const Text("Voulez-vous vraiment signaler cette publication ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              "Signaler",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      print("Signaler");
    }
  }

  void _copyLink(BuildContext context) {
    final link =
        "https://example.com/p/${Uri.encodeComponent(widget.publication.title)}";
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Lien copié")),
    );
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
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
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

class Comment {
  final String name;
  final String text;
  final String time;

  const Comment({
    required this.name,
    required this.text,
    required this.time,
  });
}
