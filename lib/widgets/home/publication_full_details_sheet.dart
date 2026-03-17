import 'package:flutter/material.dart';

import '../../services/api_service.dart' show ApiService, ApiListingComment;
import '../image_viewer_page.dart';
import 'home_models.dart';

class PublicationFullDetailsSheet extends StatefulWidget {
  const PublicationFullDetailsSheet({
    super.key,
    required this.publication,
    required this.red,
    required this.green,
    required this.textGray,
    required this.mutedGray,
    required this.purple,
    this.initialComments = const [],
    this.onCommentsChanged,
  });

  final Publication publication;
  final Color red;
  final Color green;
  final Color textGray;
  final Color mutedGray;
  final Color purple;
  final List<ApiListingComment> initialComments;
  final ValueChanged<List<ApiListingComment>>? onCommentsChanged;

  @override
  State<PublicationFullDetailsSheet> createState() =>
      _PublicationFullDetailsSheetState();
}

class _PublicationFullDetailsSheetState
    extends State<PublicationFullDetailsSheet> {
  final TextEditingController _commentController = TextEditingController();
  late final PageController _imagePageController;
  late List<ApiListingComment> _comments;
  int _currentImageIndex = 0;
  bool _canComment = false;
  bool _loadingComments = false;
  bool _commentsLoaded = false;
  String? _commentsError;
  bool _submittingComment = false;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _comments = List<ApiListingComment>.from(widget.initialComments);
    _canComment = ApiService.instance.isAuthenticated;
    _commentsLoaded = _comments.isNotEmpty;
    _syncCommentAccess();
    if (!_commentsLoaded) {
      _loadComments();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _loadingComments = true;
      _commentsError = null;
    });

    try {
      final comments =
          await ApiService.instance.fetchComments(widget.publication.id);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _commentsLoaded = true;
      });
      widget.onCommentsChanged?.call(List<ApiListingComment>.from(_comments));
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
      });
      widget.onCommentsChanged?.call(List<ApiListingComment>.from(_comments));
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

  Future<void> _syncCommentAccess() async {
    final canComment = await ApiService.instance.syncStoredAuthSession();
    if (!mounted) return;
    setState(() => _canComment = canComment);
  }

  Future<void> _openImageViewer(int initialIndex) async {
    final images = widget.publication.imageUrls;
    if (images.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewerPage(
          images: images,
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

  Widget _buildImageGallery(Publication publication) {
    final images = publication.imageUrls;
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasMultipleImages = images.length > 1;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PageView.builder(
                  controller: _imagePageController,
                  itemCount: images.length,
                  onPageChanged: (index) {
                    if (!mounted) return;
                    setState(() => _currentImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final imageUrl = images[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openImageViewer(index),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) {
                                  return child;
                                }

                                final expected =
                                    loadingProgress.expectedTotalBytes;
                                final progress = expected == null || expected == 0
                                    ? null
                                    : loadingProgress.cumulativeBytesLoaded /
                                        expected;

                                return Container(
                                  color: Colors.black12,
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 2.4,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.grey.shade300,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.image, size: 48),
                                  ),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Voir",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (hasMultipleImages)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1} / ${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hasMultipleImages) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (index) {
              final isActive = index == _currentImageIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 8,
                width: isActive ? 18 : 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? widget.purple
                      : widget.mutedGray.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final publication = widget.publication;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, controller) {
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
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: publication.status == PublicationStatus.perdu
                                ? widget.red
                                : widget.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            publication.status == PublicationStatus.perdu
                                ? "PERDU"
                                : "TROUV\u00C9",
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
                    const SizedBox(height: 12),
                    if (publication.imageUrls.isNotEmpty)
                      _buildImageGallery(publication),
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
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                          onPressed: _loadComments,
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else if (_commentsError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _comments.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final author = comment.fullName.isNotEmpty
                              ? comment.fullName
                              : ((comment.userId != null &&
                                      comment.userId != 0)
                                  ? "Utilisateur #${comment.userId}"
                                  : "Utilisateur");
                          final timeLabel = _formatRelative(comment.createdAt);

                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFE5E7EB),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  comment.content,
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
              if (_canComment)
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
                                child: CircularProgressIndicator(strokeWidth: 2),
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
                ),
            ],
          );
        },
      ),
    );
  }
}



