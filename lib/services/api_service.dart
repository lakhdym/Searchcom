import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service centralisé pour communiquer avec l'API PHP (auth + annonces).
///
/// Pour l'instant :
/// - login \"mock\" via auth_login.php (n'importe quel email/mot de passe non vides)
/// - récupération des annonces via annonces.php (table `listings`)
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  /// URL de base de l'API.
  /// En local XAMPP :  http://localhost/searchcom/api
  /// En prod :        https://www.italents.ma/app/api
  static const String baseUrlProd = 'https://italents.ma/app/api';
  static const String baseUrlLocal = 'http://localhost/searchcom/api';

  /// Switch auto : build release -> prod, build debug/profile -> local.
  /// Ajuste si tu veux forcer un env.
  final String _baseUrl = baseUrlProd; // ✅ دائما prod

  final http.Client _client = http.Client();

  String? _token;

  /// Effectue un login simple sur `auth_login.php` et stocke le JWT en mémoire.
  ///
  /// Pour le moment, l'API accepte n'importe quel email/mot de passe non vides
  /// et renvoie toujours un token avec `sub = 1`.
  Future<String> _loginIfNeeded() async {
    if (_token != null) return _token!;

    final uri = Uri.parse('$_baseUrl/auth_login.php');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'demo@searchcom.ma',
        'password': 'passwordDemo123', // uniquement pour les tests
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur de login (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Réponse de login invalide : token manquant');
    }

    _token = token;
    return token;
  }

  /// Représentation d'une annonce telle que renvoyée par `annonces.php`.
  Future<List<ApiListing>> fetchListings({
    String? type,
    bool requireAuth = false,
  }) async {
    if (requireAuth) {
      _token = await _loginIfNeeded();
    }
    final queryParameters = <String, String>{};
    if (type == 'lost' || type == 'found') {
      queryParameters['type'] = type!;
    }

    final uri = Uri.parse('$_baseUrl/annonces.php').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    // Lecture publique : on n'impose plus le token.
    // Si un token est déjà présent (utilisateur connecté ailleurs), on l'envoie quand même.
    final headers = <String, String>{};
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }

    final response = await _client.get(
      uri,
      headers: headers.isEmpty ? null : headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur lors de la récupération des annonces '
        '(${response.statusCode}): ${response.body}',
      );
    }

    final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
    return jsonList
        .map((e) => ApiListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// RÃ©cupÃ¨re les commentaires d'une annonce.
  Future<List<ApiListingComment>> fetchComments(int listingId) async {
    final uri = Uri.parse(
      '$_baseUrl/comments.php',
    ).replace(queryParameters: {'listing_id': '$listingId'});

    final headers = <String, String>{};
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }

    final response = await _client.get(
      uri,
      headers: headers.isEmpty ? null : headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur lors de la rÃ©cupÃ©ration des commentaires '
        '(${response.statusCode}): ${response.body}',
      );
    }

    final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
    return jsonList
        .map((e) => ApiListingComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// RÃ©cupÃ¨re les likes d'une annonce.
  Future<List<ApiListingLike>> fetchLikes(int listingId) async {
    final uri = Uri.parse(
      '$_baseUrl/likes.php',
    ).replace(queryParameters: {'listing_id': '$listingId'});

    final headers = <String, String>{};
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }

    final response = await _client.get(
      uri,
      headers: headers.isEmpty ? null : headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur lors de la rÃ©cupÃ©ration des likes '
        '(${response.statusCode}): ${response.body}',
      );
    }

    final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
    return jsonList
        .map((e) => ApiListingLike.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Ajoute un commentaire sur une annonce (auth nÃ©cessaire).
  Future<ApiListingComment> addComment({
    required int listingId,
    required String content,
  }) async {
    final token = await _loginIfNeeded();

    final uri = Uri.parse('$_baseUrl/comments.php');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'listing_id': listingId, 'content': content}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Erreur lors de l\'ajout du commentaire '
        '(${response.statusCode}): ${response.body}',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    return ApiListingComment.fromJson(json);
  }
}

/// Modèle simple représentant une annonce telle que renvoyée par l'API.
class ApiListing {
  final int id;
  final String type; // 'lost' ou 'found'
  final String status; // 'pending_payment', 'published', ...
  final String title;
  final String description;
  final String location;
  final String city;
  final String date;
  final bool isBoosted;
  final String? imageUrl;
  final List<String> images;
  final int likesCount;
  final int commentsCount;

  ApiListing({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.location,
    required this.city,
    required this.date,
    required this.isBoosted,
    required this.imageUrl,
    required this.images,
    required this.likesCount,
    required this.commentsCount,
  });

  factory ApiListing.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final images = <String>[];
    if (rawImages is List) {
      for (final img in rawImages) {
        if (img is String && img.trim().isNotEmpty) {
          images.add(img.trim());
        }
      }
    }

    final imageUrl = (json['imageUrl'] as String?)?.trim();
    if (images.isEmpty && imageUrl != null && imageUrl.isNotEmpty) {
      images.add(imageUrl);
    }

    return ApiListing(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String? ?? 'lost',
      status: json['status'] as String? ?? 'published',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      city: json['city'] as String? ?? '',
      date: json['date'] as String? ?? '',
      isBoosted: (json['is_boosted'] ?? false) == true,
      imageUrl: imageUrl,
      images: images,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ApiListingLike {
  final int? userId;
  final int? listingId;
  final String fullName;
  final DateTime? createdAt;

  ApiListingLike({
    required this.userId,
    required this.listingId,
    required this.fullName,
    required this.createdAt,
  });

  factory ApiListingLike.fromJson(Map<String, dynamic> json) {
    final rawDate = json['created_at'] as String?;
    DateTime? parsed;
    if (rawDate != null && rawDate.isNotEmpty) {
      parsed = DateTime.tryParse(rawDate);
    }

    return ApiListingLike(
      userId: (json['user_id'] as num?)?.toInt(),
      listingId: (json['listing_id'] as num?)?.toInt(),
      fullName: json['full_name'] as String? ?? '',
      createdAt: parsed,
    );
  }
}

class ApiListingComment {
  final int id;
  final int listingId;
  final String fullName;
  final int? userId;
  final String content;
  final String? status;
  final DateTime? createdAt;

  ApiListingComment({
    required this.id,
    required this.listingId,
    required this.fullName,
    required this.userId,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  factory ApiListingComment.fromJson(Map<String, dynamic> json) {
    final rawDate = json['created_at'] as String?;
    DateTime? parsed;
    if (rawDate != null && rawDate.isNotEmpty) {
      parsed = DateTime.tryParse(rawDate);
    }

    return ApiListingComment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      listingId: (json['listing_id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String? ?? '',
      userId: (json['user_id'] as num?)?.toInt(),
      content: json['content'] as String? ?? '',
      status: json['status'] as String?,
      createdAt: parsed,
    );
  }
}
