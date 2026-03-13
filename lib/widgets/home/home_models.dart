import 'package:flutter/material.dart';

enum PublicationStatus { perdu, trouve }

typedef HeaderBuilder = Widget Function(ValueChanged<String> onSearchChanged);

class Publication {
  final int id;
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
      imageUrls.isNotEmpty ? imageUrls.first : fallbackImageUrl;
}

const String fallbackImageUrl =
    'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=900&q=60';
