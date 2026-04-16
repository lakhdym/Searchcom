import 'dart:async';

// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_messages.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../models/user_model.dart';
import '../../../pages/app_error_page.dart';
import '../../../pages/main_app_shell.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_local_storage.dart';
import '../../../services/l10n_helper.dart';
import '../../../widgets/image_viewer_page.dart';
import '../models/chat_models.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({super.key, required this.conversation});
  final ChatConversation conversation;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  List<ChatMessage> _messages = [];
  final _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmoji = false;
  bool _searchMode = false;
  String _searchQuery = '';
  bool _isBlocked = false;
  bool _blockedByOther = false;
  final _imagePicker = ImagePicker();
  ChatMessage? _replyTo;
  UserModel? _me;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  int get _conversationId => int.tryParse(widget.conversation.id) ?? 0;

  @override
  void initState() {
    super.initState();
    _init();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmoji) {
        setState(() => _showEmoji = false);
      }
    });
  }

  Future<void> _init() async {
    try {
      _me = await AuthLocalStorage.instance.getUser();
      if (_me == null) {
        setState(() => _error = t('sign_in_to_chat'));
        return;
      }
      await _loadMessages();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _loadMessages(silent: true),
      );
    } catch (e) {
      setState(() {
        _error = AppErrorMapper.message(
          e,
          fallbackMessage: AppMessages.messagesLoadError(),
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    final me = _me;
    if (me == null) return;
    try {
      final result = await ApiService.instance.getMessages(
        conversationId: _conversationId,
        userId: me.id,
      );
      final items = result['items'] as List<Map<String, dynamic>>;
      final mapped = items
          .map((item) => _mapApiMessage(item, currentUserId: me.id))
          .toList();
      final mergedMessages = _mergePendingLocalMessages(mapped);
      if (!mounted) return;
      setState(() {
        _messages = mergedMessages;
        _isBlocked = result['blocked'] == true;
        _blockedByOther = result['blockedByOther'] == true;
        _error = null;
      });
      if (mergedMessages.isNotEmpty) {
        widget.conversation.lastMessage = mergedMessages.last;
      }
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = AppErrorMapper.message(
          e,
          fallbackMessage: AppMessages.messagesLoadError(),
        );
      });
    }
  }

  List<ChatMessage> _mergePendingLocalMessages(
    List<ChatMessage> serverMessages,
  ) {
    final pendingLocals = _messages
        .where((message) => message.id.startsWith('local_'))
        .toList();
    if (pendingLocals.isEmpty) {
      return serverMessages;
    }

    final merged = [...serverMessages];
    for (final pending in pendingLocals) {
      final alreadyConfirmed = merged.any(
        (serverMessage) => _isSamePendingMessage(pending, serverMessage),
      );
      if (!alreadyConfirmed) {
        merged.add(pending);
      }
    }
    merged.sort((a, b) => a.time.compareTo(b.time));
    return merged;
  }

  bool _isSamePendingMessage(ChatMessage pending, ChatMessage serverMessage) {
    if (!pending.id.startsWith('local_')) return false;
    if (!pending.isMe || !serverMessage.isMe) return false;
    if (pending.messageType != serverMessage.messageType) return false;
    if (pending.replyToMessageId != serverMessage.replyToMessageId) {
      return false;
    }

    final sameTimeWindow =
        serverMessage.time.difference(pending.time).abs() <
        const Duration(minutes: 2);
    if (!sameTimeWindow) return false;

    if (pending.isImage && serverMessage.isImage) {
      return true;
    }

    return (pending.text ?? '') == (serverMessage.text ?? '');
  }

  ChatMessage _mapApiMessage(
    Map<String, dynamic> data, {
    required int currentUserId,
  }) {
    final senderId = data['sender_user_id']?.toString() ?? '';
    final text = _normalizeText(data['content']?.toString());
    final messageType = data['message_type']?.toString() ?? 'text';
    final rawDeleted = data['is_deleted_for_all'];
    final isDeleted =
        rawDeleted == true ||
        rawDeleted == 1 ||
        rawDeleted == '1' ||
        rawDeleted == 'true' ||
        (messageType == 'system' &&
            (text == '[deleted]' || text?.toLowerCase() == 'message supprime'));
    return ChatMessage(
      id: data['id'].toString(),
      conversationId: widget.conversation.id,
      senderId: senderId,
      messageType: messageType,
      text: text,
      mediaUrl: _resolveChatMediaUrl(data['media_url']?.toString()),
      isMe: senderId == currentUserId.toString(),
      time: _parseMessageTime(data['created_at']?.toString()),
      status: senderId == currentUserId.toString() ? MessageStatus.sent : null,
      replyToMessageId: data['reply_to_message_id']?.toString(),
      isDeletedForEveryone: isDeleted,
      deletedText: data['deleted_text']?.toString() ?? 'Message supprime',
    );
  }

  String? _resolveChatMediaUrl(String? raw) {
    const uploadsBase = 'https://italents.ma/app/';
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http')) return trimmed;

    var cleaned = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    final uploadsIndex = cleaned.indexOf('uploads/');
    if (uploadsIndex >= 0) {
      cleaned = cleaned.substring(uploadsIndex);
    } else if (!cleaned.startsWith('chat/')) {
      cleaned = 'chat/$cleaned';
    }

    if (!cleaned.startsWith('uploads/')) {
      cleaned = 'uploads/$cleaned';
    }
    return '$uploadsBase$cleaned';
  }

  DateTime _parseMessageTime(String? raw) {
    try {
      return raw != null ? DateTime.parse(raw) : DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  String? _normalizeText(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _focusNode.dispose();
    _scrollController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scheduleStatusProgression(ChatMessage msg) {
    // placeholders only; backend handles real status
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleSearch() {
    setState(() {
      _searchMode = !_searchMode;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Future<void> _reportConversationBackend() async {
    final me = _me;
    if (me == null) {
      _showSnack('Session requise');
      return;
    }
    final reasons = [
      "Spam ou publicitÃƒÂ©",
      "Discours haineux",
      "Arnaque / fraude",
      "Contenu inappropriÃƒÂ©",
      "Autre",
    ];
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                "Signaler la conversation",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ...reasons.map(
              (r) => ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(r),
                onTap: () => Navigator.pop(ctx, r),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
    if (choice == null) return;
    try {
      final convId = int.tryParse(widget.conversation.id) ?? 0;
      await ApiService.instance.reportConversation(
        conversationId: convId,
        userId: me.id,
        reason: choice,
      );
      _showSnack("Signalement enregistrÃƒÂ© et utilisateur bloquÃƒÂ©");
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  Future<void> _reportConversation() async => _reportConversationBackend();

  Future<void> _toggleBlock() async {
    if (_blockedByOther) {
      _showSnack("Vous ÃƒÂªtes bloquÃƒÂ© dans cette conversation.");
      return;
    }
    final me = _me;
    if (me == null) {
      _showSnack('Session requise');
      return;
    }
    try {
      final convId = int.tryParse(widget.conversation.id) ?? 0;
      final next = !_isBlocked;
      final blocked = await ApiService.instance.toggleBlockConversation(
        conversationId: convId,
        userId: me.id,
        block: next,
      );
      setState(() {
        _isBlocked = blocked;
        if (!blocked) _error = null;
      });
      if (!blocked) {
        _loadMessages(silent: true);
      }
      _showSnack(blocked ? 'Utilisateur bloquÃƒÂ©' : 'Blocage retirÃƒÂ©');
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  void _sendText() {
    if (_isBlocked) {
      _showSnack("Vous etes bloque dans cette conversation.");
      return;
    }
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _sendMessage(text);
  }

  Future<void> _sendMessage(String text) async {
    final me = _me;
    if (me == null) {
      AppFeedback.showInfoSnackBar(context, AppMessages.sessionExpired());
      return;
    }

    final replyTarget = _replyTo;
    final localMsg = ChatMessage(
      id: 'local_text_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      senderId: me.id.toString(),
      messageType: 'text',
      text: text,
      isMe: true,
      time: DateTime.now(),
      status: MessageStatus.sent,
      replyToMessageId: replyTarget?.id,
      replyExcerpt: _replyExcerpt(replyTarget),
    );

    setState(() {
      _messages.add(localMsg);
      widget.conversation.lastMessage = localMsg;
      widget.conversation.unreadCount = 0;
      _replyTo = null;
      _showEmoji = false;
    });
    _messageController.clear();
    _scrollAfterInsert();

    try {
      final saved = await ApiService.instance.sendMessage(
        conversationId: _conversationId,
        userId: me.id,
        content: text,
        messageType: 'text',
        replyToMessageId: replyTarget?.id,
      );
      final confirmed = _mapApiMessage(saved, currentUserId: me.id);
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere(
          (message) => message.id == localMsg.id,
        );
        if (idx != -1) {
          _messages[idx] = confirmed;
        } else {
          _messages.add(confirmed);
        }
        widget.conversation.lastMessage = confirmed;
      });
    } catch (e) {
      _handleSendFailure(
        e,
        localMessageId: localMsg.id,
        fallbackMessage: AppMessages.messageSendError(),
      );
    }
  }

  Future<void> _pickImage() async {
    if (_isBlocked) {
      _showSnack("Vous etes bloque dans cette conversation.");
      return;
    }

    final me = _me;
    if (me == null) {
      AppFeedback.showInfoSnackBar(context, AppMessages.sessionExpired());
      return;
    }

    ChatMessage? localMsg;
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final imageBytes = await picked.readAsBytes();
      final replyTarget = _replyTo;
      final imageMessage = ChatMessage(
        id: 'local_image_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: widget.conversation.id,
        senderId: me.id.toString(),
        messageType: 'image',
        localImageBytes: imageBytes,
        isMe: true,
        time: DateTime.now(),
        isUploading: true,
        replyToMessageId: replyTarget?.id,
        replyExcerpt: _replyExcerpt(replyTarget),
      );
      localMsg = imageMessage;

      setState(() {
        _messages.add(imageMessage);
        widget.conversation.lastMessage = imageMessage;
        widget.conversation.unreadCount = 0;
        _replyTo = null;
        _showEmoji = false;
      });
      _scrollAfterInsert();

      final saved = await ApiService.instance.sendImageMessage(
        conversationId: _conversationId,
        userId: me.id,
        image: picked,
        replyToMessageId: replyTarget?.id,
      );
      final confirmed = _mapApiMessage(saved, currentUserId: me.id);
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere(
          (message) => message.id == imageMessage.id,
        );
        if (idx != -1) {
          _messages[idx] = confirmed;
        } else {
          _messages.add(confirmed);
        }
        widget.conversation.lastMessage = confirmed;
      });
    } catch (e) {
      _handleSendFailure(
        e,
        localMessageId: localMsg?.id,
        fallbackMessage: t('image_send_error'),
      );
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final msg = ChatMessage(
      id: 'local_file_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      messageType: 'file',
      fileName: file.name,
      fileSize: file.size,
      isMe: true,
      time: DateTime.now(),
      status: MessageStatus.sent,
      replyToMessageId: _replyTo?.id,
      replyExcerpt: _replyExcerpt(_replyTo),
    );
    setState(() {
      _messages.add(msg);
      widget.conversation.lastMessage = msg;
      widget.conversation.unreadCount = 0;
      _replyTo = null;
      _showEmoji = false;
    });
    _scheduleStatusProgression(msg);
    _scrollAfterInsert();
  }

  Future<void> _openImageViewer(String imageUrl) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ImageViewerPage(images: [imageUrl])),
    );
  }

  String? _replyExcerpt(ChatMessage? message) {
    if (message == null) return null;
    final excerpt = chatMessagePreviewText(
      message,
      imageLabel: t('image_attachment'),
      fileLabel: t('file_attachment'),
    ).trim();
    return excerpt.isEmpty ? null : excerpt;
  }

  void _handleSendFailure(
    Object error, {
    String? localMessageId,
    required String fallbackMessage,
  }) {
    if (!mounted) return;
    final message = AppErrorMapper.message(
      error,
      fallbackMessage: fallbackMessage,
    );
    final normalized = message.toLowerCase();
    final blocked = normalized.contains('bloqu');

    setState(() {
      if (localMessageId != null) {
        _messages.removeWhere((item) => item.id == localMessageId);
      }
      if (_messages.isNotEmpty) {
        widget.conversation.lastMessage = _messages.last;
      }
      if (blocked) {
        _isBlocked = true;
        _blockedByOther = true;
      }
    });

    _showSnack(blocked ? 'Vous etes bloque dans cette conversation.' : message);
  }

  void _scrollAfterInsert() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    final newOffset = start + emoji.length;
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  void _onLongPressMessage(ChatMessage message) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_outlined),
              title: Text(t('reply')),
              onTap: () => Navigator.pop(context, 'reply'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(t('delete')),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            if (message.text != null && message.text!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(t('copy')),
                onTap: () => Navigator.pop(context, 'copy'),
              ),
          ],
        ),
      ),
    );

    if (result == 'reply') {
      if (!mounted) return;
      setState(() => _replyTo = message);
      FocusScope.of(context).unfocus();
    } else if (result == 'delete') {
      await _confirmDelete(message);
    } else if (result == 'copy' && message.text != null) {
      await Clipboard.setData(ClipboardData(text: message.text!));
      if (mounted) {
        AppFeedback.showSuccessSnackBar(context, t('text_copied'));
      }
    }
  }

  Future<void> _confirmDelete(ChatMessage msg) async {
    final isMine = msg.isMe;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete_message')),
        content: Text(t('choose_an_option')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'me'),
            child: Text(t('delete_for_me')),
          ),
          if (isMine)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'all'),
              child: Text(t('delete_for_everyone')),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(t('cancel_button')),
          ),
        ],
      ),
    );

    if (choice == null) return;
    final me = _me;
    final messageId = int.tryParse(msg.id);
    final deleteForAll = choice == 'all' && isMine;

    // Snapshot for rollback en cas d'ÃƒÂ©chec rÃƒÂ©seau
    final previous = List<ChatMessage>.from(_messages);

    if (choice == 'me') {
      setState(() => _messages.removeWhere((m) => m.id == msg.id));
    } else if (deleteForAll) {
      final idx = _messages.indexWhere((m) => m.id == msg.id);
      if (idx != -1) {
        setState(() {
          _messages[idx] = ChatMessage(
            id: msg.id,
            conversationId: msg.conversationId,
            isMe: msg.isMe,
            time: msg.time,
            isDeletedForEveryone: true,
            deletedText: t('message_deleted_by_you'),
            status: msg.status,
          );
        });
      }
    }

    if (messageId != null && me != null) {
      try {
        await ApiService.instance.deleteMessage(
          messageId: messageId,
          userId: me.id,
          deleteForAll: deleteForAll,
        );
      } catch (e) {
        if (!mounted) return;
        // rollback UI
        setState(() {
          _messages = previous;
          _error = "Suppression ÃƒÂ©chouÃƒÂ©e : ${e.toString()}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ãƒâ€°chec de suppression, rÃƒÂ©essayez."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return AuthenticatedScaffold(
        currentIndex: mainAppShellChatIndex,
        backgroundColor: scheme.surface,
        appBar: AppBar(title: Text(t('conversation'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      final kind = AppErrorMapper.isNotFound(_error!)
          ? AppErrorKind.conversationNotFound
          : AppErrorMapper.isUnauthorized(_error!)
          ? AppErrorKind.unauthorized
          : AppErrorKind.unexpected;
      return AppErrorPage(kind: kind, message: _error, onRetry: _init);
    }
    final textTheme = Theme.of(context).textTheme;
    final filteredMessages = (_searchMode && _searchQuery.isNotEmpty)
        ? _messages
              .where(
                (m) =>
                    !m.isDeletedForEveryone &&
                    (m.text ?? '').toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList()
        : _messages;

    final Map<String, ChatMessage> messageMap = {
      for (final m in _messages) m.id: m,
    };

    return AuthenticatedScaffold(
      currentIndex: mainAppShellChatIndex,
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0.4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: _searchMode
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher dans la conversation',
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : Row(
                children: [
                  CircleAvatar(
                    radius: 18,
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
                  const SizedBox(width: 10),
                  Text(
                    widget.conversation.user.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _searchMode ? Icons.close : Icons.search,
              color: scheme.onSurface,
            ),
            onPressed: _toggleSearch,
          ),
          if (!_blockedByOther) ...[
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: scheme.onSurface),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'search':
                    _toggleSearch();
                    break;
                  case 'report':
                    _reportConversation();
                    break;
                  case 'block':
                    _toggleBlock();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'report',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.flag_outlined, color: scheme.error),
                    title: Text('Signaler et bloquer'),
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.block, color: scheme.error),
                    title: Text(_isBlocked ? 'DÃƒÂ©bloquer' : 'Bloquer'),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: filteredMessages.length,
                itemBuilder: (context, index) {
                  final msg = filteredMessages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Align(
                      alignment: msg.isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: msg.isDeletedForEveryone
                            ? null
                            : () => _onLongPressMessage(msg),
                        behavior: HitTestBehavior.opaque,
                        child: MessageBubble(
                          message: msg,
                          repliedTo: msg.replyToMessageId != null
                              ? messageMap[msg.replyToMessageId]
                              : null,
                          onOpenImage: msg.mediaUrl == null
                              ? null
                              : () => _openImageViewer(msg.mediaUrl!),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isBlocked)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                color: scheme.surfaceContainerHighest,
                child: Text(
                  _blockedByOther
                      ? "Vous ÃƒÂªtes bloquÃƒÂ© par ce contact. Vous ne pouvez pas envoyer de messages."
                      : "Conversation bloquÃƒÂ©e. DÃƒÂ©bloquez pour reprendre.",
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              if (_replyTo != null)
                ReplyPreviewBar(
                  message: _replyTo!,
                  onCancel: () => setState(() => _replyTo = null),
                ),
              ChatInputBar(
                controller: _messageController,
                focusNode: _focusNode,
                onSend: _sendText,
                onPickImage: _pickImage,
                onPickFile: _pickFile,
                onToggleEmoji: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _showEmoji = !_showEmoji);
                },
              ),
              // Temporarily commented out emoji picker
              // if (_showEmoji)
              //   SizedBox(
              //     height: 250,
              //     child: EmojiPicker(
              //       onEmojiSelected: (category, emoji) =>
              //           _insertEmoji(emoji.emoji),
              //       config: const Config(
              //         emojiViewConfig: EmojiViewConfig(
              //           columns: 7,
              //           emojiSizeMax: 32,
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.repliedTo,
    this.onOpenImage,
  });

  final ChatMessage message;
  final ChatMessage? repliedTo;
  final VoidCallback? onOpenImage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isMe = message.isMe;
    final isDeleted = message.isDeletedForEveryone;
    final bg = isMe ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = isDeleted
        ? (isMe
              ? scheme.onPrimary.withValues(alpha: 0.85)
              : scheme.onSurfaceVariant)
        : (isMe ? scheme.onPrimary : scheme.onSurface);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDeleted)
                Text(
                  message.deletedText,
                  style: textTheme.bodyMedium?.copyWith(
                    color: fg.withValues(alpha: 0.85),
                    fontStyle: FontStyle.italic,
                  ),
                )
              else ...[
                if (repliedTo != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border(
                        left: BorderSide(
                          color: fg.withValues(alpha: 0.5),
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repliedTo!.isMe ? t('you') : t('reply_label'),
                          style: textTheme.labelMedium?.copyWith(
                            color: fg.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chatMessagePreviewText(
                            repliedTo!,
                            imageLabel: t('image_attachment'),
                            fileLabel: t('file_attachment'),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: fg.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (message.isImage) ...[
                  _ImageBubbleContent(
                    message: message,
                    foregroundColor: fg,
                    placeholderColor: isMe
                        ? scheme.onPrimary.withValues(alpha: 0.12)
                        : scheme.surface,
                    onTap: message.mediaUrl != null && !message.isUploading
                        ? onOpenImage
                        : null,
                  ),
                  const SizedBox(height: 6),
                ] else if (message.isFile && message.fileName != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.insert_drive_file, color: fg, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            message.fileName!,
                            style: textTheme.bodyMedium?.copyWith(color: fg),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (message.fileSize != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatSize(message.fileSize!),
                            style: textTheme.labelSmall?.copyWith(
                              color: fg.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ] else if (message.text != null) ...[
                  Text(
                    message.text!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: fg,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(message.time),
                    style: textTheme.labelSmall?.copyWith(
                      color: fg.withValues(alpha: 0.7),
                    ),
                  ),
                  if (!isDeleted && message.showStatus) ...[
                    const SizedBox(width: 6),
                    _StatusTicks(status: message.status!, color: fg),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} Ko';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} Mo';
  }
}

class _ImageBubbleContent extends StatelessWidget {
  const _ImageBubbleContent({
    required this.message,
    required this.foregroundColor,
    required this.placeholderColor,
    this.onTap,
  });

  final ChatMessage message;
  final Color foregroundColor;
  final Color placeholderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 240, height: 180, child: _buildImage()),
        ),
        if (message.isUploading)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(14),
            child: const CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
      ],
    );

    if (onTap == null) {
      return content;
    }
    return GestureDetector(onTap: onTap, child: content);
  }

  Widget _buildImage() {
    if (message.localImageBytes != null) {
      return Image.memory(
        message.localImageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorState(),
      );
    }
    if (message.mediaUrl != null) {
      return Image.network(
        message.mediaUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingState();
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorState(),
      );
    }
    return _buildErrorState();
  }

  Widget _buildLoadingState() {
    return DecoratedBox(
      decoration: BoxDecoration(color: placeholderColor),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: foregroundColor,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return DecoratedBox(
      decoration: BoxDecoration(color: placeholderColor),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: foregroundColor,
          size: 32,
        ),
      ),
    );
  }
}

class _StatusTicks extends StatelessWidget {
  const _StatusTicks({required this.status, required this.color});
  final MessageStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final delivered = Icons.done_all_rounded;
    final sent = Icons.done_rounded;
    if (status == MessageStatus.sent) {
      return Icon(sent, size: 16, color: color.withValues(alpha: 0.9));
    } else if (status == MessageStatus.delivered) {
      return Icon(delivered, size: 16, color: color.withValues(alpha: 0.9));
    } else {
      return Icon(delivered, size: 16, color: Colors.lightBlueAccent);
    }
  }
}

class ReplyPreviewBar extends StatelessWidget {
  const ReplyPreviewBar({
    super.key,
    required this.message,
    required this.onCancel,
  });

  final ChatMessage message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: scheme.surfaceContainerHighest,
      child: Row(
        children: [
          Container(width: 3, height: 42, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.isMe ? t('reply_to_you') : t('reply_label'),
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.text ??
                      (message.isImage
                          ? t('image_attachment')
                          : message.isFile
                          ? t('file_attachment')
                          : ''),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onCancel,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onPickImage,
    required this.onPickFile,
    required this.onToggleEmoji,
    this.focusNode,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final VoidCallback onToggleEmoji;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            InkWell(
              onTap: onToggleEmoji,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.emoji_emotions_outlined,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            InkWell(
              onTap: onPickFile,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.attach_file, color: scheme.onSurfaceVariant),
              ),
            ),
            InkWell(
              onTap: onPickImage,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.image_outlined,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: t('write_message'),
                    border: InputBorder.none,
                  ),
                  onTap: () => FocusScope.of(context).requestFocus(focusNode),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onSend,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: scheme.onPrimary,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
