import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/chat/pages/conversations_page.dart';
import '../../services/api_service.dart';
import '../image_viewer_page.dart';
import 'home_models.dart';
import 'publication_actions_menu.dart';
import 'publication_contact_chip.dart';
import 'publication_contact_menu.dart';
import 'publication_full_details_sheet.dart';

class PublicationCard extends StatefulWidget {
  const PublicationCard({
    super.key,
    required this.publication,
    required this.purple,
    required this.red,
    required this.green,
    required this.textGray,
    required this.mutedGray,
  });

  final Publication publication;
  final Color purple;
  final Color red;
  final Color green;
  final Color textGray;
  final Color mutedGray;

  @override
  State<PublicationCard> createState() => _PublicationCardState();
}

class _PublicationCardState extends State<PublicationCard>
    with TickerProviderStateMixin {
  bool _showComments = false;
  final TextEditingController _commentController = TextEditingController();
  late final PageController _pageController;
  int _currentImage = 0;
  bool _canComment = false;
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _liked = widget.publication.likedByMe;
    _likesCount = widget.publication.likesCount;
    _canComment = ApiService.instance.isAuthenticated;
    _syncCommentAccess();
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
    if (willShow) {
      _syncCommentAccess();
    }
  }

  Future<void> _syncCommentAccess() async {
    final canComment = await ApiService.instance.syncStoredAuthSession();
    if (!mounted) return;
    setState(() => _canComment = canComment);
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
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _commentsLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _commentsError = e.toString();
      });
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
      if (!mounted) return;
      setState(() {
        _likes = likes;
        _likesLoaded = true;
        _likesCount = likes.length;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _likesError = e.toString();
      });
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
      final result = await ApiService.instance.toggleLike(widget.publication.id);
      if (!mounted) return;
      setState(() {
        _liked = result.liked;
        _likesCount = result.likesCount;
        _likesLoaded = false;
        _likes = [];
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible de mettre \u00E0 jour le like"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _likeBusy = false);
      }
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

    await showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (context) {
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
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
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

    final canComment = await ApiService.instance.syncStoredAuthSession();
    if (!mounted) return;
    if (!canComment) {
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
      ).showSnackBar(const SnackBar(content: Text("Commentaire ajout\u00E9")));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _commentsError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'envoyer le commentaire")),
      );
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

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return PublicationFullDetailsSheet(
          publication: widget.publication,
          red: widget.red,
          green: widget.green,
          textGray: widget.textGray,
          mutedGray: widget.mutedGray,
          purple: widget.purple,
          initialComments: _commentsLoaded ? _comments : const [],
          onCommentsChanged: (comments) {
            if (!mounted) return;
            setState(() {
              _comments = comments;
              _commentsLoaded = true;
              _commentsError = null;
            });
          },
        );
      },
    );
  }

  Future<void> _openImageViewer(int initialIndex) async {
    if (widget.publication.imageUrls.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewerPage(
          images: widget.publication.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  String _formatRelative(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "A l'instant";
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Il y a ${diff.inHours} h";
    if (diff.inDays < 7) return "Il y a ${diff.inDays} j";
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "${date.year}-$month-$day";
  }

  @override
  Widget build(BuildContext context) {
    final publication = widget.publication;
    final badgeColor = publication.status == PublicationStatus.perdu
        ? widget.red
        : widget.green;
    final badgeLabel = publication.status == PublicationStatus.perdu
        ? "PERDU"
        : "TROUV\u00C9";
    final radius = BorderRadius.circular(16);
    final commentCount =
        _commentsLoaded ? _comments.length : publication.commentsCount;
    final hasPhone = publication.ownerPhone?.trim().isNotEmpty ?? false;
    final hasContactOptions = publication.contactChat ||
        (publication.contactWhatsApp && hasPhone) ||
        (publication.contactCall && hasPhone);
    final longDescription = publication.description.length > 140;

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
                  onPageChanged: (index) => setState(() => _currentImage = index),
                  itemCount: publication.imageUrls.length,
                  itemBuilder: (context, index) {
                    final image = publication.imageUrls[index];
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openImageViewer(index),
                      child: Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stackTrace) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.white,
                          ),
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
                    children: List.generate(publication.imageUrls.length, (index) {
                      final active = index == _currentImage;
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
                  builder: (buttonContext) => GestureDetector(
                    onTap: () => _showPublicationMenu(buttonContext),
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
              /*
                if (hasContactOptions) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (publication.contactWhatsApp && hasPhone)
                        _buildContactChip(
                          icon: Icons.chat_bubble,
                          label: "WhatsApp",
                          color: const Color(0xFF25D366),
                          bg: const Color(0xFFE8F8EF),
                          onTap: () =>
                              _launchWhatsApp(publication.ownerPhone ?? ''),
                        ),
                      if (publication.contactCall && hasPhone)
                        _buildContactChip(
                          icon: Icons.call,
                          label: "Appeler",
                          color: const Color(0xFF2563EB),
                          bg: const Color(0xFFE8ECFF),
                          onTap: () => _launchCall(publication.ownerPhone ?? ''),
                        ),
                      if (publication.contactChat)
                        _buildContactChip(
                          icon: Icons.chat_bubble_outline,
                          label: "Chat",
                          color: widget.purple,
                          bg: const Color(0xFFF1E9FF),
                          onTap: _openInternalChat,
                        ),
                    ],
                  ),
                ],*/
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
                        "$_likesCount",
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
            child: _showComments ? _buildCommentsSection() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Padding(
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
                  child: CircularProgressIndicator(strokeWidth: 2),
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
                  child: const Text("R\u00E9essayer"),
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
            ..._comments.map(_buildCommentItem),
          if (_canComment) ...[
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
                        hintText: "\u00C9crire un commentaire\u2026",
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
                            child: CircularProgressIndicator(strokeWidth: 2),
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
        ],
      ),
    );
  }

  Widget _buildCommentItem(ApiListingComment comment) {
    final author = comment.fullName.isNotEmpty
        ? comment.fullName
        : ((comment.userId != null && comment.userId != 0)
            ? "Utilisateur #${comment.userId}"
            : "Utilisateur");
    final initial = author.isNotEmpty ? author[0] : '?';
    final timeLabel = _formatRelative(comment.createdAt);

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  comment.content,
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
  }

  Future<void> _showConversationMenu(BuildContext context) async {
    await PublicationContactMenu.show(
      context: context,
      contactWhatsApp: widget.publication.contactWhatsApp,
      contactCall: widget.publication.contactCall,
      contactChat: widget.publication.contactChat,
      ownerPhone: widget.publication.ownerPhone,
      purple: widget.purple,
    );
  }

  void _showPublicationMenu(BuildContext buttonContext) {
    PublicationActionsMenu.show(
      context: buttonContext,
      publication: widget.publication,
    );
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
      _showSnack("Num\u00E9ro WhatsApp indisponible");
      return;
    }

    final uri = Uri.parse('https://wa.me/$normalized');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        _showSnack("Impossible d'ouvrir WhatsApp");
      }
    } catch (_) {
      if (mounted) {
        _showSnack("Impossible d'ouvrir WhatsApp");
      }
    }
  }

  Future<void> _launchCall(String rawPhone) async {
    final normalized = _normalizedPhone(rawPhone);
    if (normalized == null) {
      _showSnack("Num\u00E9ro d'appel indisponible");
      return;
    }

    final uri = Uri(scheme: 'tel', path: normalized);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        _showSnack("Impossible d'ouvrir le composeur");
      }
    } catch (_) {
      if (mounted) {
        _showSnack("Impossible d'ouvrir le composeur");
      }
    }
  }

  void _openInternalChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConversationsPage()),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildContactChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    Color? bg,
  }) {
    return PublicationContactChip(
      icon: icon,
      label: label,
      onTap: onTap,
      color: color ?? widget.purple,
      bg: bg ?? Colors.grey.shade100,
    );
  }
}



