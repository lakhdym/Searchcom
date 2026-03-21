import 'package:flutter/material.dart';

enum MessageStatus { sent, delivered, read }

class ChatUser {
  final String id;
  final String name;
  final Color avatarColor;

  const ChatUser({
    required this.id,
    required this.name,
    required this.avatarColor,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts.first.characters.take(1).toString() +
            parts.last.characters.take(1).toString())
        .toUpperCase();
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String? text;
  final String? imagePath;
  final String? fileName;
  final int? fileSize;
  final bool isMe;
  final DateTime time;

  MessageStatus? status;
  String? replyToMessageId;
  String? replyExcerpt;

  bool isDeletedForEveryone;
  String deletedText;

  ChatMessage({
    required this.id,
    required this.conversationId,
    this.senderId = '',
    this.text,
    this.imagePath,
    this.fileName,
    this.fileSize,
    required this.isMe,
    required this.time,
    this.status,
    this.replyToMessageId,
    this.replyExcerpt,
    this.isDeletedForEveryone = false,
    this.deletedText = 'Vous avez supprimé ce message',
  });

  bool get isImage => imagePath != null;
  bool get isFile => fileName != null;
  bool get isText => text != null && !isImage && !isFile;
  bool get showStatus => isMe && status != null && !isDeletedForEveryone;
}

class ChatConversation {
  final String id;
  final ChatUser user;
  final String? listingTitle;
  int unreadCount;
  ChatMessage lastMessage;
  final bool blockedByMe;
  final bool blockedByOther;

  ChatConversation({
    required this.id,
    required this.user,
    this.listingTitle,
    required this.unreadCount,
    required this.lastMessage,
    this.blockedByMe = false,
    this.blockedByOther = false,
  });
}
