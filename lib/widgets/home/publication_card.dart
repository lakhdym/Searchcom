import 'package:flutter/material.dart';

import '../../comment_api_extension.dart';
import '../../core/constants/app_messages.dart';
import '../../core/errors/app_error_mapper.dart';
import '../../core/feedback/app_feedback.dart';
import '../../services/api_service.dart';
import '../../services/auth_local_storage.dart';
import '../../services/l10n_helper.dart';
import '../../state/auth_state.dart';
import '../comments/comment_action_dialogs.dart';
import '../comments/comment_list_item.dart';
import '../image_viewer_page.dart';
import 'home_models.dart';
import 'publication_actions_menu.dart';
import 'publication_contact_menu.dart';
import 'publication_date_formatter.dart';
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
    this.onPublicationChanged,
  });

  final Publication publication;
  final Color purple;
  final Color red;
  final Color green;
  final Color textGray;
  final Color mutedGray;
  final ValueChanged<Publication>? onPublicationChanged;

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
  int? _meId;
  bool _meLoaded = false;
  List<ApiListingComment> _comments = [];
  bool _loadingComments = false;
  bool _commentsSyncing = false;
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
  final Set<int> _commentActionIds = <int>{};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _liked = widget.publication.likedByMe;
    _likesCount = widget.publication.likesCount;
    _canComment = ApiService.instance.isAuthenticated;
    _syncCommentAccess();
    currentUser.addListener(_syncCurrentUser);
    _loadMe();
  }

  @override
  void dispose() {
    currentUser.removeListener(_syncCurrentUser);
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PublicationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.publication.likesCount != widget.publication.likesCount ||
        oldWidget.publication.likedByMe != widget.publication.likedByMe) {
      _likesCount = widget.publication.likesCount;
      _liked = widget.publication.likedByMe;
    }
  }

  void _syncCurrentUser() {
    if (!mounted) return;
    setState(() {
      _meId = currentUser.value?.id;
      _meLoaded = true;
    });
  }

  void _emitPublicationChanged({
    int? likesCount,
    int? commentsCount,
    bool? likedByMe,
  }) {
    final callback = widget.onPublicationChanged;
    if (callback == null) return;

    callback(
      widget.publication.copyWith(
        likesCount: likesCount ?? _likesCount,
        commentsCount:
            commentsCount ??
            (_commentsLoaded
                ? _comments.length
                : widget.publication.commentsCount),
        likedByMe: likedByMe ?? _liked,
      ),
    );
  }

  void _toggleComments() {
    final willShow = !_showComments;
    setState(() => _showComments = willShow);
    if (!willShow) {
      return;
    }

    _syncCommentAccess();
    _loadComments(silent: _commentsLoaded);
  }

  Future<void> _syncCommentAccess() async {
    final canComment = await ApiService.instance.syncStoredAuthSession();
    if (!mounted) return;
    setState(() => _canComment = canComment);
  }

  Future<void> _loadComments({bool silent = false}) async {
    if (_commentsSyncing) return;
    _commentsSyncing = true;

    if (!silent) {
      setState(() {
        _loadingComments = true;
        _commentsError = null;
      });
    } else {
      _commentsError = null;
    }

    try {
      final comments = await ApiService.instance.fetchComments(
        widget.publication.id,
      );
      if (!mounted) return;
      final commentsCount = comments.length;
      setState(() {
        _comments = comments;
        _commentsLoaded = true;
        _commentsError = null;
      });
      _emitPublicationChanged(commentsCount: commentsCount);
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _commentsError = e.toString();
        });
      }
    } finally {
      if (mounted && !silent) {
        setState(() {
          _loadingComments = false;
        });
      }
      _commentsSyncing = false;
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
      final likesCount = likes.length;
      setState(() {
        _likes = likes;
        _likesLoaded = true;
        _likesCount = likesCount;
      });
      _emitPublicationChanged(likesCount: likesCount);
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
      final result = await ApiService.instance.toggleLike(
        widget.publication.id,
      );
      if (!mounted) return;
      final nextLiked = result.liked;
      final nextLikesCount = result.likesCount;
      setState(() {
        _liked = nextLiked;
        _likesCount = nextLikesCount;
        _likesLoaded = false;
        _likes = [];
      });
      _emitPublicationChanged(
        likesCount: nextLikesCount,
        likedByMe: nextLiked,
      );
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
        final scheme = Theme.of(context).colorScheme;
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
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Aucun like pour l'instant.",
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
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
                backgroundColor: scheme.surfaceContainer,
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              title: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
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
      final nextComments = <ApiListingComment>[newComment, ..._comments];
      setState(() {
        _comments = nextComments;
        _commentsLoaded = true;
        _showComments = true;
      });
      _emitPublicationChanged(commentsCount: nextComments.length);
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

  void _replaceComment(ApiListingComment updatedComment) {
    final index = _comments.indexWhere((item) => item.id == updatedComment.id);
    if (index < 0) return;
    _comments[index] = updatedComment;
  }

  void _setCommentBusy(int commentId, bool busy) {
    setState(() {
      if (busy) {
        _commentActionIds.add(commentId);
      } else {
        _commentActionIds.remove(commentId);
      }
    });
  }

  Future<void> _editComment(ApiListingComment comment) async {
    final updatedText = await CommentActionDialogs.showEditDialog(
      context,
      initialContent: comment.content,
    );
    if (!mounted || updatedText == null) return;

    _setCommentBusy(comment.id, true);
    try {
      final updatedComment = await ApiService.instance.updateComment(
        commentId: comment.id,
        content: updatedText,
      );
      if (!mounted) return;
      setState(() => _replaceComment(updatedComment));
      AppFeedback.showSuccessSnackBar(context, t('comment_updated_success'));
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showErrorSnackBar(
        context,
        AppErrorMapper.message(e, fallbackMessage: t('comment_update_error')),
      );
    } finally {
      if (mounted) {
        _setCommentBusy(comment.id, false);
      }
    }
  }

  Future<void> _deleteComment(ApiListingComment comment) async {
    final confirmed = await CommentActionDialogs.showDeleteConfirmation(
      context,
    );
    if (!mounted || !confirmed) return;

    _setCommentBusy(comment.id, true);
    try {
      final deletedComment = await ApiService.instance.deleteComment(
        commentId: comment.id,
      );
      if (!mounted) return;
      setState(() => _replaceComment(deletedComment));
      AppFeedback.showSuccessSnackBar(context, t('comment_deleted_success'));
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showErrorSnackBar(
        context,
        AppErrorMapper.message(e, fallbackMessage: t('comment_delete_error')),
      );
    } finally {
      if (mounted) {
        _setCommentBusy(comment.id, false);
      }
    }
  }

  Future<void> _reportComment(ApiListingComment comment) async {
    final canComment = await ApiService.instance.syncStoredAuthSession();
    if (!mounted) return;
    if (!canComment) {
      AppFeedback.showInfoSnackBar(context, t('sign_in_to_report'));
      return;
    }

    final report = await CommentActionDialogs.showReportSheet(context);
    if (!mounted || report == null) return;

    _setCommentBusy(comment.id, true);
    try {
      await ApiService.instance.reportComment(
        commentId: comment.id,
        reason: report.reason,
        details: report.details,
      );
      if (!mounted) return;
      AppFeedback.showSuccessSnackBar(context, AppMessages.reportSentSuccess());
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showErrorSnackBar(
        context,
        AppErrorMapper.message(e, fallbackMessage: t('comment_report_error')),
      );
    } finally {
      if (mounted) {
        _setCommentBusy(comment.id, false);
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
            _emitPublicationChanged(commentsCount: comments.length);
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
    if (diff.inMinutes < 1) return t('just_now');
    if (diff.inMinutes < 60) {
      if (diff.inMinutes == 1) return t('minute_ago');
      return t('minutes_ago').replaceFirst('{count}', '${diff.inMinutes}');
    }
    if (diff.inHours < 24) {
      if (diff.inHours == 1) return t('hour_ago');
      return t('hours_ago').replaceFirst('{count}', '${diff.inHours}');
    }
    if (diff.inDays < 7) {
      if (diff.inDays == 1) return t('day_ago');
      return t('days_ago').replaceFirst('{count}', '${diff.inDays}');
    }
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "${date.year}-$month-$day";
  }

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final publication = widget.publication;
    final badgeColor = publication.status == PublicationStatus.perdu
        ? widget.red
        : widget.green;
    final badgeLabel = publication.status == PublicationStatus.perdu
        ? "PERDU"
        : "TROUV\u00C9";
    final radius = BorderRadius.circular(18);
    final cardColor = isDark ? scheme.surface : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE5E7EB);
    final textPrimary = scheme.onSurface;
    final textSecondary = scheme.onSurfaceVariant;
    final commentCount = (_showComments && _commentsLoaded)
        ? _comments.length
        : publication.commentsCount;
    final currentUserId = _currentUserId;
    final listing = publication;
    final isOwner = listing.userId.toString() == currentUserId.toString();
    final hasPhone = publication.ownerPhone?.trim().isNotEmpty ?? false;
    final hasContactOptions =
        !isOwner &&
        (publication.contactChat ||
            (publication.contactWhatsApp && hasPhone) ||
            (publication.contactCall && hasPhone));
    final longDescription = publication.description.length > 140;
    final formattedEventDate = formatPublicationEventDate(
      publication.eventDate,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: radius,
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: isDark ? 28 : 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
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
                  onPageChanged: (index) =>
                      setState(() => _currentImage = index),
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
                          color: isDark
                              ? scheme.surfaceContainer
                              : Colors.grey.shade300,
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
                    children: List.generate(publication.imageUrls.length, (
                      index,
                    ) {
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
                    gradient: LinearGradient(
                      colors: [badgeColor, badgeColor.withValues(alpha: 0.78)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
              if (_meLoaded && !isOwner)
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
                          color: isDark
                              ? scheme.surface.withValues(alpha: 0.86)
                              : Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: textSecondary,
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: widget.mutedGray,
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
                    color: textSecondary,
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
                          color: textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (formattedEventDate.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 16,
                        color: widget.purple,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${t('event_date')}: $formattedEventDate',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: cardBorder),
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
                        style: TextStyle(fontSize: 13, color: textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: _toggleComments,
                  child: Row(
                    children: [
                      Icon(
                        Icons.mode_comment_outlined,
                        size: 18,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$commentCount",
                        style: TextStyle(fontSize: 13, color: textPrimary),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (hasContactOptions && _meLoaded && !isOwner)
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
                ? _buildCommentsSection()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    final scheme = Theme.of(context).colorScheme;
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
                Text(
                  "Impossible de charger les commentaires.",
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                "Aucun commentaire",
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            )
          else ...[
            ..._comments.take(5).map(_buildCommentItem),
            if (_comments.length > 5) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _openFullDetails,
                  child: Text(
                    "Voir plus de commentaires",
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
          if (_canComment) ...[
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      minLines: 1,
                      maxLines: 3,
                      style: TextStyle(color: scheme.onSurface),
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
              ? "${t('guest_user')} #${comment.userId}"
              : t('guest_user'));
    final timeLabel = _formatRelative(comment.createdAt);

    return CommentListItem(
      comment: comment,
      authorLabel: author,
      timeLabel: timeLabel,
      currentUserId: _meId,
      isBusy: _commentActionIds.contains(comment.id),
      compact: true,
      onEdit: _editComment,
      onDelete: _deleteComment,
      onReport: _reportComment,
    );
  }

  Future<void> _showConversationMenu(BuildContext context) async {
    await PublicationContactMenu.show(
      context: context,
      listingId: widget.publication.id,
      listingTitle: widget.publication.title,
      ownerId: widget.publication.ownerId,
      currentUserId: _currentUserId,
      ownerName: widget.publication.ownerName,
      contactWhatsApp: widget.publication.contactWhatsApp,
      contactCall: widget.publication.contactCall,
      contactChat: widget.publication.contactChat,
      requiresContactPayment:
          widget.publication.status == PublicationStatus.trouve,
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

  Future<void> _loadMe() async {
    final user = currentUser.value ?? await AuthLocalStorage.instance.getUser();
    if (!mounted) return;
    setState(() {
      _meId = user?.id;
      _meLoaded = true;
    });
  }

  String? get _currentUserId => _meId?.toString();
}
