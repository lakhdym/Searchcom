import 'package:flutter/material.dart';

enum PublicationStatus { perdu, trouve }

typedef HeaderBuilder = Widget Function(
  TextEditingController searchController,
  ValueChanged<String> onSearchChanged,
  VoidCallback onFilterTap,
  int activeFilterCount,
);

class Publication {
  final int id;
  final int ownerId;
  final String title;
  final PublicationStatus status;
  final List<String> imageUrls;
  final String dateText;
  final String eventDate;
  final String description;
  final String cityArea;
  final int? categoryId;
  final String? categoryName;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;
  final bool contactChat;
  final bool contactWhatsApp;
  final bool contactCall;
  final String? ownerPhone;
  final String? ownerName;

  Publication({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.status,
    required this.imageUrls,
    required this.dateText,
    required this.eventDate,
    required this.description,
    required this.cityArea,
    this.categoryId,
    this.categoryName,
    required this.likesCount,
    required this.commentsCount,
    required this.likedByMe,
    required this.contactChat,
    required this.contactWhatsApp,
    required this.contactCall,
    required this.ownerPhone,
    this.ownerName,
  });

  Publication copyWith({
    int? id,
    int? ownerId,
    String? title,
    PublicationStatus? status,
    List<String>? imageUrls,
    String? dateText,
    String? eventDate,
    String? description,
    String? cityArea,
    int? categoryId,
    String? categoryName,
    int? likesCount,
    int? commentsCount,
    bool? likedByMe,
    bool? contactChat,
    bool? contactWhatsApp,
    bool? contactCall,
    String? ownerPhone,
    String? ownerName,
  }) {
    return Publication(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      dateText: dateText ?? this.dateText,
      eventDate: eventDate ?? this.eventDate,
      description: description ?? this.description,
      cityArea: cityArea ?? this.cityArea,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedByMe: likedByMe ?? this.likedByMe,
      contactChat: contactChat ?? this.contactChat,
      contactWhatsApp: contactWhatsApp ?? this.contactWhatsApp,
      contactCall: contactCall ?? this.contactCall,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerName: ownerName ?? this.ownerName,
    );
  }

  String get primaryImage =>
      imageUrls.isNotEmpty ? imageUrls.first : fallbackImageUrl;

  int get userId => ownerId;
}

const String fallbackImageUrl =
    'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=900&q=60';
