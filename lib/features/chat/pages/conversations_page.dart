import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../../../pages/main_app_shell.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_local_storage.dart';
import '../../../services/l10n_helper.dart';
import '../models/chat_models.dart';
import 'chat_detail_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  List<ChatConversation> _convs = [];
  String _query = '';
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
    _loadConversations();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _loadConversations(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final filtered = _convs.where((conversation) {
      if (_query.isEmpty) return true;
      return conversation.user.name.toLowerCase().contains(_query) ||
          (conversation.listingTitle?.toLowerCase().contains(_query) ?? false);
    }).toList();

    return AuthenticatedScaffold(
      currentIndex: mainAppShellChatIndex,
      isTabRoot: true,
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0.4,
        title: Text(
          'Messages',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(
                    alpha: 0.7,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: scheme.primary, width: 1.4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: TextStyle(color: scheme.error)),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final conversation = filtered[index];
                    return ConversationTile(
                      conversation: conversation,
                      onTap: () async {
                        if (conversation.unreadCount > 0) {
                          setState(() => conversation.unreadCount = 0);
                        }
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatDetailPage(conversation: conversation),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final user = await AuthLocalStorage.instance.getUser();
      if (user == null) {
        setState(() {
          _error = 'Vous devez vous connecter pour voir vos messages.';
          _convs = [];
        });
        return;
      }

      final data = await ApiService.instance.getConversations(userId: user.id);
      final mapped = data
          .map((item) => _mapApiConv(item, user))
          .whereType<ChatConversation>()
          .toList();
      if (!mounted) return;
      setState(() => _convs = mapped);
    } catch (e) {
      if (!mounted || silent) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted && !silent) {
        setState(() => _loading = false);
      }
    }
  }

  ChatConversation? _mapApiConv(Map<String, dynamic> json, UserModel me) {
    try {
      final otherId = json['other_user_id']?.toString() ?? '';
      final otherName = json['other_user_name']?.toString() ?? 'Contact';
      final listingTitle = json['listing_title']?.toString();
      final lastMsg = json['last_message']?.toString();
      final lastMessageType = json['last_message_type']?.toString() ?? 'text';
      final lastMediaUrl = json['last_media_url']?.toString();
      final lastSenderId = json['last_sender_user_id']?.toString() ?? '';
      final hasMessagePreview =
          (lastMsg != null && lastMsg.trim().isNotEmpty) ||
          lastMessageType == 'image' ||
          (lastMediaUrl != null && lastMediaUrl.trim().isNotEmpty);
      if (!hasMessagePreview) {
        return null;
      }

      final lastAtRaw = json['last_message_at']?.toString();
      DateTime lastAt;
      try {
        lastAt = lastAtRaw != null ? DateTime.parse(lastAtRaw) : DateTime.now();
      } catch (_) {
        lastAt = DateTime.now();
      }

      final unread = int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0;
      final blockedByMe =
          json['blocked_by_me'] == 1 || json['blocked_by_me'] == true;
      final blockedByOther =
          json['blocked_by_other'] == 1 || json['blocked_by_other'] == true;
      final isDeleted =
          lastMessageType == 'system' &&
          (lastMsg?.trim() == '[deleted]' ||
              lastMsg?.toLowerCase() == 'message supprime');

      return ChatConversation(
        id: json['id'].toString(),
        user: ChatUser(
          id: otherId,
          name: otherName,
          avatarColor: _colorFromString(otherId),
        ),
        listingTitle: listingTitle,
        unreadCount: unread,
        lastMessage: ChatMessage(
          id: 'last_${json['id']}',
          conversationId: json['id'].toString(),
          senderId: lastSenderId,
          messageType: lastMessageType,
          text: (lastMsg == null || lastMsg.trim().isEmpty) ? null : lastMsg,
          mediaUrl: (lastMediaUrl == null || lastMediaUrl.trim().isEmpty)
              ? null
              : lastMediaUrl,
          isMe: lastSenderId == me.id.toString(),
          time: lastAt,
          isDeletedForEveryone: isDeleted,
          deletedText: 'Message supprime',
        ),
        blockedByMe: blockedByMe,
        blockedByOther: blockedByOther,
      );
    } catch (_) {
      return null;
    }
  }

  Color _colorFromString(String input) {
    final hash = input.codeUnits.fold(0, (p, c) => p + c);
    return Colors.primaries[hash % Colors.primaries.length];
  }
}

class ConversationTile extends StatefulWidget {
  const ConversationTile({super.key, required this.conversation, this.onTap});

  final ChatConversation conversation;
  final VoidCallback? onTap;

  @override
  State<ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<ConversationTile> {
  bool _busy = false;
  late bool _isBlocked;
  late bool _blockedByOther;

  @override
  void initState() {
    super.initState();
    _isBlocked = widget.conversation.blockedByMe;
    _blockedByOther = widget.conversation.blockedByOther;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: widget.conversation.user.avatarColor
                    .withValues(alpha: 0.15),
                child: Text(
                  widget.conversation.user.initials,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.conversation.user.avatarColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.conversation.user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(widget.conversation.lastMessage.time),
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.conversation.listingTitle != null &&
                                    widget.conversation.listingTitle!.isNotEmpty
                                ? 'A propos de : ${widget.conversation.listingTitle}'
                                : _lastMessagePreview(
                                    widget.conversation.lastMessage,
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (widget.conversation.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${widget.conversation.unreadCount}',
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (!_blockedByOther)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'open':
                        widget.onTap?.call();
                        break;
                      case 'block':
                        _toggleBlock(!_isBlocked);
                        break;
                      case 'report':
                        _report();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.open_in_new),
                        title: Text('Ouvrir'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'block',
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          _isBlocked ? Icons.lock_open : Icons.block,
                        ),
                        title: Text(_isBlocked ? 'Debloquer' : 'Bloquer'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.flag_outlined),
                        title: Text('Signaler'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      final hh = time.hour.toString().padLeft(2, '0');
      final mm = time.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  String _lastMessagePreview(ChatMessage message) {
    return chatMessagePreviewText(
      message,
      imageLabel: t('image_attachment'),
      fileLabel: t('file_attachment'),
    );
  }

  Future<void> _toggleBlock(bool block) async {
    if (_blockedByOther) {
      _showSnack('Vous avez ete bloque dans cette conversation.');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final me = await AuthLocalStorage.instance.getUser();
      if (me == null) {
        _showSnack('Connectez-vous');
        return;
      }
      final convId = int.tryParse(widget.conversation.id) ?? 0;
      await ApiService.instance.toggleBlockConversation(
        conversationId: convId,
        userId: me.id,
        block: block,
      );
      setState(() => _isBlocked = block);
      _showSnack(block ? 'Conversation bloquee' : 'Blocage retire');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _report() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final me = await AuthLocalStorage.instance.getUser();
      if (me == null) {
        _showSnack('Connectez-vous');
        return;
      }
      final convId = int.tryParse(widget.conversation.id) ?? 0;
      await ApiService.instance.reportConversation(
        conversationId: convId,
        userId: me.id,
        reason: 'Signale depuis la liste',
      );
      _showSnack('Conversation signalee');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

