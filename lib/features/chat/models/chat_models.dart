import 'dart:typed_data';

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
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.take(1).toString() +
            parts.last.characters.take(1).toString())
        .toUpperCase();
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String messageType;
  final String? text;
  final String? mediaUrl;
  final Uint8List? localImageBytes;
  final String? fileName;
  final int? fileSize;
  final bool isMe;
  final DateTime time;
  final bool isUploading;

  MessageStatus? status;
  String? replyToMessageId;
  String? replyExcerpt;

  bool isDeletedForEveryone;
  String deletedText;

  ChatMessage({
    required this.id,
    required this.conversationId,
    this.senderId = '',
    this.messageType = 'text',
    this.text,
    this.mediaUrl,
    this.localImageBytes,
    this.fileName,
    this.fileSize,
    required this.isMe,
    required this.time,
    this.isUploading = false,
    this.status,
    this.replyToMessageId,
    this.replyExcerpt,
    this.isDeletedForEveryone = false,
    this.deletedText = 'Message supprime',
  });

  bool get isImage =>
      messageType == 'image' || mediaUrl != null || localImageBytes != null;
  bool get isFile => fileName != null;
  bool get isText => !isImage && !isFile && (text?.isNotEmpty ?? false);
  bool get showStatus =>
      isMe && status != null && !isDeletedForEveryone && !isUploading;
}

String chatMessagePreviewText(
  ChatMessage message, {
  required String imageLabel,
  required String fileLabel,
}) {
  if (message.isDeletedForEveryone) {
    return message.deletedText;
  }

  final text = message.text?.trim();
  if (text != null && text.isNotEmpty) {
    return text;
  }
  if (message.isImage) {
    return imageLabel;
  }
  if (message.isFile) {
    return fileLabel;
  }
  return '';
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
