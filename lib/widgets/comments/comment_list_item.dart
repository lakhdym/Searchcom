import 'package:flutter/material.dart';

import '../../comment_model_extension.dart';
import '../../services/api_service.dart';
import '../../services/l10n_helper.dart';

class CommentListItem extends StatelessWidget {
  const CommentListItem({
    super.key,
    required this.comment,
    required this.authorLabel,
    required this.timeLabel,
    this.currentUserId,
    this.isBusy = false,
    this.compact = false,
    this.onEdit,
    this.onDelete,
    this.onReport,
  });

  final ApiListingComment comment;
  final String authorLabel;
  final String timeLabel;
  final int? currentUserId;
  final bool isBusy;
  final bool compact;
  final Future<void> Function(ApiListingComment comment)? onEdit;
  final Future<void> Function(ApiListingComment comment)? onDelete;
  final Future<void> Function(ApiListingComment comment)? onReport;

  bool get _isOwner =>
      currentUserId != null &&
      comment.userId != null &&
      currentUserId == comment.userId;

  bool get _canShowMenu {
    if (isBusy || comment.isDeleted) return false;
    if (_isOwner) {
      return onEdit != null || onDelete != null;
    }
    return onReport != null;
  }

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initial = authorLabel.isNotEmpty ? authorLabel[0].toUpperCase() : '?';

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: compact ? 14 : 18,
            backgroundColor: scheme.primary.withValues(alpha: 0.1),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 0 : 2,
                vertical: compact ? 0 : 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              authorLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            Text(
                              timeLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            if (comment.isEdited && !comment.isDeleted)
                              Text(
                                t('comment_edited'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isBusy)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_canShowMenu)
                        PopupMenuButton<String>(
                          tooltip: t('comment_actions'),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_vert,
                            size: compact ? 18 : 20,
                            color: scheme.onSurfaceVariant,
                          ),
                          onSelected: (value) async {
                            switch (value) {
                              case 'edit':
                                await onEdit?.call(comment);
                                break;
                              case 'delete':
                                await onDelete?.call(comment);
                                break;
                              case 'report':
                                await onReport?.call(comment);
                                break;
                            }
                          },
                          itemBuilder: (context) {
                            final items = <PopupMenuEntry<String>>[];
                            if (_isOwner && onEdit != null) {
                              items.add(
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit_outlined, size: 18),
                                      const SizedBox(width: 10),
                                      Text(t('edit')),
                                    ],
                                  ),
                                ),
                              );
                            }
                            if (_isOwner && onDelete != null) {
                              items.add(
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(t('delete')),
                                    ],
                                  ),
                                ),
                              );
                            }
                            if (!_isOwner && onReport != null) {
                              items.add(
                                PopupMenuItem<String>(
                                  value: 'report',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.flag_outlined, size: 18),
                                      const SizedBox(width: 10),
                                      Text(t('report')),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return items;
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.isDeleted ? t('comment_deleted') : comment.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: comment.isDeleted
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                      fontStyle: comment.isDeleted
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
