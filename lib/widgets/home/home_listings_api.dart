import 'dart:convert' show jsonDecode, utf8, latin1;

import 'package:http/http.dart' as http;

import '../../services/api_service.dart' show ApiService;
import '../../services/auth_local_storage.dart';

class HomeListingsApi {
  HomeListingsApi._();

  static final HomeListingsApi instance = HomeListingsApi._();

  final http.Client _client = http.Client();

  Future<List<HomeListingItem>> fetchListings({
    String? type,
    int limit = 5,
    int offset = 0,
  }) async {
    final token = await AuthLocalStorage.instance.getToken();
    final query = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      ...?(type == null ? null : <String, String>{'type': type}),
    };
    final uri = Uri.parse(
      '${ApiService.baseUrlProd}/annonces.php',
    ).replace(queryParameters: query);
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final resp = await _client.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception(
        'Erreur chargement annonces (${resp.statusCode}): ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body);
    if (data is! List) return const <HomeListingItem>[];

    return data
        .whereType<Map<String, dynamic>>()
        .map(HomeListingItem.fromJson)
        .toList(growable: false);
  }
}

class HomeListingItem {
  final int id;
  final int? ownerId;
  final String? ownerName;
  final String type;
  final String title;
  final String description;
  final String location;
  final String city;
  final String date;
  final String? eventDate;
  final String? imageUrl;
  final List<String> images;
  final int commentsCount;
  final int likesCount;
  final bool likedByMe;
  final bool contactChat;
  final bool contactWhatsApp;
  final bool contactCall;
  final String? ownerPhone;

  HomeListingItem({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    required this.city,
    required this.date,
    required this.eventDate,
    required this.imageUrl,
    required this.images,
    required this.commentsCount,
    required this.likesCount,
    required this.likedByMe,
    required this.contactChat,
    required this.contactWhatsApp,
    required this.contactCall,
    required this.ownerPhone,
  });

  factory HomeListingItem.fromJson(Map<String, dynamic> json) {
    String fixUtf8(String? v) {
      if (v == null) return '';
      try {
        return utf8.decode(latin1.encode(v));
      } catch (_) {
        return v;
      }
    }

    final images = (json['images'] is List)
        ? (json['images'] as List).map((e) => e.toString()).toList()
        : <String>[];
    int? parseOwnerId() {
      final raw =
          json['owner_id'] ??
          json['ownerId'] ??
          json['user_id'] ??
          json['userId'] ??
          json['id_user'] ??
          json['idUser'];
      return raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
    }

    return HomeListingItem(
      id: (json['id'] as num).toInt(),
      ownerId: parseOwnerId(),
      ownerName: () {
        final raw = (json['owner_name'] ?? json['user_name'] ?? '').toString();
        final fixed = fixUtf8(raw).trim();
        return fixed.isNotEmpty ? fixed : null;
      }(),
      type: json['type']?.toString() ?? 'lost',
      title: fixUtf8(json['title']?.toString()),
      description: fixUtf8(json['description']?.toString()),
      location: fixUtf8(
        json['location']?.toString() ?? json['city']?.toString(),
      ),
      city: fixUtf8(json['city']?.toString()),
      date: json['date']?.toString() ?? '',
      eventDate: json['event_date']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      images: images,
      commentsCount: json['comments_count'] is num
          ? (json['comments_count'] as num).toInt()
          : int.tryParse(json['comments_count']?.toString() ?? '0') ?? 0,
      likesCount: json['likes_count'] is num
          ? (json['likes_count'] as num).toInt()
          : int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
      likedByMe: json['liked_by_me'] == true || json['liked_by_me'] == 1,
      contactChat: json['contact_chat'] == true || json['contact_chat'] == 1,
      contactWhatsApp:
          json['contact_whatsapp'] == true || json['contact_whatsapp'] == 1,
      contactCall: json['contact_call'] == true || json['contact_call'] == 1,
      ownerPhone: () {
        final raw = (json['owner_phone'] ?? json['phone'] ?? '')
            .toString()
            .trim();
        return raw.isEmpty ? null : raw;
      }(),
    );
  }
}
