import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../services/auth_local_storage.dart';
import '../models/listing_model.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String baseUrlProd = 'https://italents.ma/app/api';
  final String _baseUrl = baseUrlProd;
  final http.Client _client = http.Client();

  String? _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  void setToken(String? token) {
    _token = (token != null && token.isNotEmpty) ? token : null;
  }

  Future<bool> syncStoredAuthSession() async {
    final storedToken = await AuthLocalStorage.instance.getToken();
    setToken(storedToken);
    return isAuthenticated;
  }

  Future<void> _loadTokenIfNeeded() async {
    if (_token != null && _token!.isNotEmpty) return;
    final stored = await AuthLocalStorage.instance.getToken();
    if (stored != null && stored.isNotEmpty) _token = stored;
  }

  Map<String, String> _buildHeaders({
    bool withAuth = false,
    bool json = false,
  }) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (withAuth && _token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // -------------------------------------------------------------
  // Categories
  // -------------------------------------------------------------
  Future<List<ApiCategory>> fetchCategories() async {
    final uri = Uri.parse('$_baseUrl/get_categories.php');
    final resp = await _client.get(uri, headers: _buildHeaders());
    if (resp.statusCode != 200) {
      throw Exception(
        'Erreur chargement categories (${resp.statusCode}): ${resp.body}',
      );
    }
    final decoded = jsonDecode(resp.body);
    final list = (decoded is Map && decoded['categories'] is List)
        ? decoded['categories']
        : (decoded is List ? decoded : null);
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(ApiCategory.fromJson)
          .toList();
    }
    throw Exception('RÃƒÆ’Ã‚Â©ponse catÃƒÆ’Ã‚Â©gories invalide');
  }

  // -------------------------------------------------------------
  // Listings (public)
  // -------------------------------------------------------------
  Future<List<ApiListing>> fetchListings({
    String? type,
    int limit = 5,
    int offset = 0,
  }) async {
    await _loadTokenIfNeeded(); // pour liked_by_me si token stockÃƒÆ’Ã‚Â©
    final query = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      ...?(type == null ? null : <String, String>{'type': type}),
    };
    final uri = Uri.parse(
      '$_baseUrl/annonces.php',
    ).replace(queryParameters: query);
    final resp = await _client.get(uri, headers: _buildHeaders(withAuth: true));
    if (resp.statusCode != 200) {
      throw Exception(
        'Erreur chargement annonces (${resp.statusCode}): ${resp.body}',
      );
    }
    final data = jsonDecode(resp.body);
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ApiListing.fromJson)
        .toList();
  }

  // -------------------------------------------------------------
  // Creation annonce
  // -------------------------------------------------------------
  Future<CreateListingResult> createListing({
    required String type, // 'lost' ou 'found'
    required String title,
    required String description,
    required String city,
    String? locationText,
    int? categoryId,
    DateTime? eventDate,
    bool contactChat = true,
    bool contactWhatsApp = true,
    bool contactCall = true,
  }) async {
    await _loadTokenIfNeeded();
    if (!isAuthenticated) throw ApiAuthRequired('User not authenticated');

    final uri = Uri.parse('$_baseUrl/annonces.php');
    final body = <String, dynamic>{
      'type': type,
      'title': title,
      'description': description,
      'city': city,
      'location_text': locationText ?? city,
      'contact_chat': contactChat ? 1 : 0,
      'contact_whatsapp': contactWhatsApp ? 1 : 0,
      'contact_call': contactCall ? 1 : 0,
    };
    if (categoryId != null) body['category_id'] = categoryId;
    if (eventDate != null) {
      body['event_date'] =
          '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}';
    }

    final response = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true, json: true),
      body: jsonEncode(body),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Erreur creation annonce (${response.statusCode}): ${response.body}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final requiresPayment = data['requires_payment'] == true;
    final listingId =
        (data['id'] ?? data['listing_id'] ?? data['listingId']) as num?;
    if (listingId == null) {
      throw Exception('Reponse creation annonce invalide: id manquant');
    }
    final paymentId = data['payment_id'] as num?;
    final amount = data['amount']?.toString();
    final currency = data['currency']?.toString();
    return CreateListingResult(
      listingId: listingId.toInt(),
      requiresPayment: requiresPayment,
      paymentId: paymentId?.toInt(),
      amount: amount,
      currency: currency,
    );
  }

  Future<void> updateListing({
    required int listingId,
    required String title,
    required String description,
    required String city,
    String? locationText,
    int? categoryId,
    DateTime? eventDate,
    bool contactChat = true,
    bool contactWhatsApp = true,
    bool contactCall = true,
  }) async {
    await _loadTokenIfNeeded();
    final user = await AuthLocalStorage.instance.getUser();
    final uri = Uri.parse('$_baseUrl/update_listing.php');
    final body = <String, dynamic>{
      'listing_id': listingId,
      if (user != null) 'user_id': user.id,
      'title': title,
      'description': description,
      'city': city,
      'location_text': locationText,
      'category_id': categoryId,
      'event_date': eventDate?.toIso8601String().split('T').first,
      'contact_chat': contactChat ? 1 : 0,
      'contact_whatsapp': contactWhatsApp ? 1 : 0,
      'contact_call': contactCall ? 1 : 0,
    };
    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true),
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw Exception('Erreur update (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Erreur lors de la mise ÃƒÆ’Ã‚Â  jour',
      );
    }
  }

  Future<void> deleteListingPhoto({
    required int listingId,
    required int photoId,
  }) async {
    await _loadTokenIfNeeded();
    final user = await AuthLocalStorage.instance.getUser();
    final uri = Uri.parse('$_baseUrl/delete_listing_photo.php');
    final body = <String, dynamic>{
      'listing_id': listingId,
      'photo_id': photoId,
      if (user != null) 'user_id': user.id,
    };
    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true),
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw Exception(
        'Erreur suppression photo (${resp.statusCode}): ${resp.body}',
      );
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Erreur lors de la suppression de la photo',
      );
    }
  }

  // -------------------------------------------------------------
  // Upload photos (listing_photos)
  // -------------------------------------------------------------
  Future<void> uploadListingPhotos(
    int listingId,
    List<ApiPickedImage> images,
  ) async {
    if (images.isEmpty) return;
    await _loadTokenIfNeeded();
    if (!isAuthenticated) throw ApiAuthRequired('User not authenticated');

    final uri = Uri.parse('$_baseUrl/upload_listing_photos.php');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_buildHeaders(withAuth: true));
    req.fields['listing_id'] = listingId.toString();
    for (final img in images) {
      if (kIsWeb) {
        req.files.add(
          http.MultipartFile.fromBytes(
            'photos[]',
            img.bytes,
            filename: img.file.name,
          ),
        );
      } else {
        req.files.add(
          await http.MultipartFile.fromPath(
            'photos[]',
            img.file.path,
            filename: img.file.name,
          ),
        );
      }
    }
    final resp = await req.send();
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      final body = await resp.stream.bytesToString();
      throw Exception('Upload photos echoue (${resp.statusCode}): $body');
    }
  }

  // -------------------------------------------------------------
  // Commentaires
  // -------------------------------------------------------------
  Future<List<ApiListingComment>> fetchComments(int listingId) async {
    final uri = Uri.parse(
      '$_baseUrl/comments.php?listing_id=$listingId&_ts=${DateTime.now().millisecondsSinceEpoch}',
    );
    final resp = await _client.get(uri, headers: _buildHeaders(withAuth: true));
    if (resp.statusCode != 200) {
      throw Exception(
        'Erreur chargement commentaires (${resp.statusCode}): ${resp.body}',
      );
    }
    final data = jsonDecode(resp.body);
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ApiListingComment.fromJson)
        .toList();
  }

  Future<ApiListingComment> addComment({
    required int listingId,
    required String content,
  }) async {
    await _loadTokenIfNeeded();
    if (!isAuthenticated) throw ApiAuthRequired('User not authenticated');

    final uri = Uri.parse('$_baseUrl/comments.php');
    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true, json: true),
      body: jsonEncode({'listing_id': listingId, 'content': content}),
    );

    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception(
        'Erreur ajout commentaire (${resp.statusCode}): ${resp.body}',
      );
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return ApiListingComment.fromJson(data);
  }

  // -------------------------------------------------------------
  // Likes
  // -------------------------------------------------------------
  Future<List<ApiListingLike>> fetchLikes(int listingId) async {
    final uri = Uri.parse(
      '$_baseUrl/likes.php?listing_id=$listingId&_ts=${DateTime.now().millisecondsSinceEpoch}',
    );
    final resp = await _client.get(uri, headers: _buildHeaders(withAuth: true));
    if (resp.statusCode != 200) {
      throw Exception(
        'Erreur chargement likes (${resp.statusCode}): ${resp.body}',
      );
    }
    final data = jsonDecode(resp.body);
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ApiListingLike.fromJson)
        .toList();
  }

  Future<LikeToggleResult> toggleLike(int listingId) async {
    await _loadTokenIfNeeded();
    if (!isAuthenticated) throw ApiAuthRequired('User not authenticated');

    final uri = Uri.parse('$_baseUrl/likes.php');
    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true, json: true),
      body: jsonEncode({'listing_id': listingId}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Erreur like (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return LikeToggleResult.fromJson(data);
  }

  // -------------------------------------------------------------
  // Conversations / Chat
  // -------------------------------------------------------------
  Future<int> getOrCreateConversation({
    required int listingId,
    required int userId,
  }) async {
    await _loadTokenIfNeeded();
    final uri = Uri.parse('$_baseUrl/get_or_create_conversation.php');
    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true, json: true),
      body: jsonEncode({'listing_id': listingId, 'user_id': userId}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Conversation (${resp.statusCode}): ${resp.body}');
    }
    final data = _decodeMap(_readResponseBody(resp));
    if (data['success'] == true) {
      final conv = data['conversation'] ?? {};
      final cid = conv['id'] ?? conv['conversation_id'];
      if (cid != null) return int.tryParse(cid.toString()) ?? (cid as int);
    }
    throw Exception(
      data['message'] ?? 'Impossible de crÃƒÆ’Ã‚Â©er la conversation',
    );
  }

  Future<List<Map<String, dynamic>>> getConversations({
    required int userId,
  }) async {
    await _loadTokenIfNeeded();
    final uri = Uri.parse('$_baseUrl/get_conversations.php');
    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true, json: true),
      body: jsonEncode({'user_id': userId}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Conversations (${resp.statusCode}): ${resp.body}');
    }
    final data = _decodeMap(_readResponseBody(resp));
    if (data['success'] == true && data['items'] is List) {
      return List<Map<String, dynamic>>.from(data['items']);
    }
    throw Exception(
      data['message'] ?? 'Impossible de charger les conversations',
    );
  }

  Future<Map<String, dynamic>> getMessages({
    required int conversationId,
    required int userId,
  }) async {
    await _loadTokenIfNeeded();
    final uri = Uri.parse('$_baseUrl/get_messages.php');
    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true, json: true),
      body: jsonEncode({'conversation_id': conversationId, 'user_id': userId}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Messages (${resp.statusCode}): ${resp.body}');
    }
    final data = _decodeMap(_readResponseBody(resp));
    if (data['success'] == true && data['items'] is List) {
      return {
        'items': List<Map<String, dynamic>>.from(data['items']),
        'blocked': data['blocked'] == true,
        'blockedByMe': data['blocked_by_me'] == true,
        'blockedByOther': data['blocked_by_other'] == true,
      };
    }
    throw Exception(data['message'] ?? 'Impossible de charger les messages');
  }

  Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required int userId,
    required String content,
    String messageType = 'text',
    String? replyToMessageId,
  }) async {
    await _loadTokenIfNeeded();
    final uri = Uri.parse('$_baseUrl/send_message.php');
    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true, json: true),
      body: jsonEncode({
        'conversation_id': conversationId,
        'user_id': userId,
        'content': content,
        'message_type': messageType,
        ...?(replyToMessageId == null
            ? null
            : {'reply_to_message_id': replyToMessageId}),
      }),
    );
    final data = _decodeMap(_readResponseBody(resp));
    if (resp.statusCode != 200) {
      throw Exception(
        _extractApiErrorMessage(
          data,
          fallback: 'Impossible d\'envoyer le message',
        ),
      );
    }
    return _extractChatMessageData(
      data,
      fallback: 'Impossible d\'envoyer le message',
    );
  }

  Future<Map<String, dynamic>> sendImageMessage({
    required int conversationId,
    required int userId,
    required XFile image,
    String? replyToMessageId,
  }) async {
    await _loadTokenIfNeeded();
    final uri = Uri.parse('$_baseUrl/send_message.php');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_buildHeaders(withAuth: true));
    req.fields['conversation_id'] = conversationId.toString();
    req.fields['user_id'] = userId.toString();
    req.fields['message_type'] = 'image';
    if (replyToMessageId != null) {
      req.fields['reply_to_message_id'] = replyToMessageId;
    }

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      req.files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: image.name),
      );
    } else {
      req.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          filename: image.name,
        ),
      );
    }

    final streamed = await req.send();
    final body = utf8.decode(
      await streamed.stream.toBytes(),
      allowMalformed: true,
    );
    final data = _decodeMap(body);
    if (streamed.statusCode != 200) {
      throw Exception(
        _extractApiErrorMessage(
          data,
          fallback: 'Impossible d\'envoyer l\'image',
        ),
      );
    }
    return _extractChatMessageData(
      data,
      fallback: 'Impossible d\'envoyer l\'image',
    );
  }

  String _readResponseBody(http.Response response) {
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  Map<String, dynamic> _extractChatMessageData(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    if (data['success'] == true) {
      final payload = data['data'] ?? data['message'];
      if (payload is Map<String, dynamic>) {
        return payload;
      }
      if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      }
    }
    throw Exception(_extractApiErrorMessage(data, fallback: fallback));
  }

  String _extractApiErrorMessage(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
    return fallback;
  }

  dynamic _decodeJsonValue(String source) {
    dynamic current = source.trim();
    if (current is! String || current.isEmpty) {
      return <String, dynamic>{};
    }

    for (var depth = 0; depth < 3; depth++) {
      if (current is! String) {
        return current;
      }

      final candidate = current.trim();
      if (candidate.isEmpty) {
        return <String, dynamic>{};
      }

      current = jsonDecode(candidate);
    }

    return current;
  }

  Map<String, dynamic> _decodeMap(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = _decodeJsonValue(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      if (decoded is String && decoded.trim().isNotEmpty) {
        return <String, dynamic>{'message': decoded.trim()};
      }
    } catch (_) {
      return <String, dynamic>{'message': trimmed};
    }

    return <String, dynamic>{'message': trimmed};
  }

  Future<void> deleteMessage({
    required int messageId,
    required int userId,
    bool deleteForAll = false,
  }) async {
    await _loadTokenIfNeeded();
    final uri = Uri.parse('$_baseUrl/delete_message.php');
    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true, json: true),
      body: jsonEncode({
        'message_id': messageId,
        'user_id': userId,
        'delete_for_all': deleteForAll ? 1 : 0,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Suppression (${resp.statusCode}): ${resp.body}');
    }
    final data = _decodeMap(_readResponseBody(resp));
    if (data['success'] == true) return;
    throw Exception(data['message'] ?? 'Impossible de supprimer le message');
  }

  Future<void> reportConversation({
    required int conversationId,
    required int userId,
    required String reason,
  }) async {
    await _loadTokenIfNeeded();
    final uri = Uri.parse('$_baseUrl/report_conversation.php');
    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true, json: true),
      body: jsonEncode({
        'conversation_id': conversationId,
        'user_id': userId,
        'reason': reason,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Signalement (${resp.statusCode}): ${resp.body}');
    }
    final data = _decodeMap(_readResponseBody(resp));
    if (data['success'] == true) return;
    throw Exception(
      data['message'] ?? 'Impossible de signaler la conversation',
    );
  }

  Future<bool> toggleBlockConversation({
    required int conversationId,
    required int userId,
    required bool block,
  }) async {
    await _loadTokenIfNeeded();
    final uri = Uri.parse('$_baseUrl/block_conversation.php');
    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true, json: true),
      body: jsonEncode({
        'conversation_id': conversationId,
        'user_id': userId,
        'block': block ? 1 : 0,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Blocage (${resp.statusCode}): ${resp.body}');
    }
    final data = _decodeMap(_readResponseBody(resp));
    if (data['success'] == true) {
      return data['blocked'] == true;
    }
    throw Exception(data['message'] ?? 'Impossible de modifier le blocage');
  }

  // -------------------------------------------------------------
  // Paiement publication
  // -------------------------------------------------------------
  Future<void> confirmPublishPayment({
    required int paymentId,
    required int listingId,
    String provider = 'cmi',
    String? providerTxnId,
  }) async {
    await _loadTokenIfNeeded();
    if (!isAuthenticated) throw ApiAuthRequired('User not authenticated');

    final uri = Uri.parse('$_baseUrl/confirm_publish_payment.php');
    final body = <String, dynamic>{
      'payment_id': paymentId,
      'listing_id': listingId,
      'provider': provider,
    };
    if (providerTxnId != null) body['provider_txn_id'] = providerTxnId;

    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true, json: true),
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw Exception(
        'Erreur confirmation paiement (${resp.statusCode}): ${resp.body}',
      );
    }
  }

  // -------------------------------------------------------------
  // Signalements
  // -------------------------------------------------------------
  Future<void> reportListing({
    required int listingId,
    required String reason,
    String? details,
  }) async {
    await _loadTokenIfNeeded();
    if (!isAuthenticated) throw ApiAuthRequired('User not authenticated');

    final uri = Uri.parse('$_baseUrl/report.php');
    final body = <String, dynamic>{
      'target_type': 'listing',
      'target_id': listingId,
      'reason': reason,
    };
    final d = details?.trim();
    if (d != null && d.isNotEmpty) body['details'] = d;

    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true, json: true),
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
      throw Exception('Erreur signalement (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    if (data is Map && data['success'] != true) {
      throw Exception(
        data['message']?.toString() ?? 'Signalement refusÃƒÆ’Ã‚Â©',
      );
    }
  }

  // -------------------------------------------------------------
  // Notifications (likes / comments)
  // -------------------------------------------------------------
  // Notifications paginÃƒÆ’Ã‚Â©es
  Future<NotificationsResult> fetchNotificationsPaged({
    required int userId,
    int page = 1,
    int perPage = 10,
    bool markRead = true,
  }) async {
    await _loadTokenIfNeeded();
    final uri = Uri.parse('$_baseUrl/get_notifications.php');
    final body = <String, dynamic>{
      'user_id': userId,
      'page': page,
      'per_page': perPage,
      'mark_read': markRead ? 1 : 0,
    };
    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true, json: true),
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw Exception('Notifications (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    if (data is Map && data['success'] == true && data['items'] is List) {
      final items = List<Map<String, dynamic>>.from(
        data['items'],
      ).map(ApiNotification.fromJson).toList();
      final unread = (data['unread_count'] is num)
          ? (data['unread_count'] as num).toInt()
          : int.tryParse(data['unread_count']?.toString() ?? '0') ?? 0;
      final total = (data['total'] is num)
          ? (data['total'] as num).toInt()
          : int.tryParse(data['total']?.toString() ?? '0') ?? items.length;
      final hasMore = data['has_more'] == true;
      final p = (data['page'] is num) ? (data['page'] as num).toInt() : page;
      final pp = (data['per_page'] is num)
          ? (data['per_page'] as num).toInt()
          : perPage;
      return NotificationsResult(
        items: items,
        unreadCount: unread,
        page: p,
        perPage: pp,
        total: total,
        hasMore: hasMore,
      );
    }
    throw Exception(
      data['message'] ?? 'Impossible de charger les notifications',
    );
  }

  Future<int> fetchNotificationsCount({
    required int userId,
    DateTime? since,
  }) async {
    await _loadTokenIfNeeded();
    final uri = Uri.parse('$_baseUrl/get_notifications_count.php');
    final body = <String, dynamic>{
      'user_id': userId,
      if (since != null) 'since': since.toIso8601String(),
    };
    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true, json: true),
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw Exception('NotifCount (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    if (data is Map && data['success'] == true) {
      final c = data['count'];
      return c is num ? c.toInt() : (int.tryParse(c?.toString() ?? '0') ?? 0);
    }
    throw Exception(
      data['message'] ?? 'Impossible de compter les notifications',
    );
  }

  Future<ListingModel> fetchListingById({
    required int listingId,
    int? userId,
  }) async {
    await _loadTokenIfNeeded();
    final uri = Uri.parse('$_baseUrl/get_listing.php');
    final resp = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: true, json: true),
      body: jsonEncode({
        'listing_id': listingId,
        ...?(userId == null ? null : {'user_id': userId}),
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Listing (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    if (data is Map && data['success'] == true && data['listing'] is Map) {
      return ListingModel.fromJson(Map<String, dynamic>.from(data['listing']));
    }
    throw Exception(data['message'] ?? 'Impossible de charger l\'annonce');
  }
}

class ApiCategory {
  final int id;
  final String slug;
  final String nameFr;
  final String nameEn;
  final String nameAr;
  ApiCategory({
    required this.id,
    required this.slug,
    required this.nameFr,
    required this.nameEn,
    required this.nameAr,
  });
  factory ApiCategory.fromJson(Map<String, dynamic> json) {
    return ApiCategory(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      slug: (json['slug'] ?? '').toString(),
      nameFr: (json['name_fr'] ?? '').toString(),
      nameEn: (json['name_en'] ?? '').toString(),
      nameAr: (json['name_ar'] ?? '').toString(),
    );
  }

  String displayName(String lang) {
    switch (lang) {
      case 'ar':
        return nameAr.isNotEmpty ? nameAr : nameFr;
      case 'en':
        return nameEn.isNotEmpty ? nameEn : nameFr;
      case 'fr':
      default:
        return nameFr;
    }
  }
}

class ApiListing {
  final int id;
  final int ownerId;
  final String? ownerName;
  final String type;
  final String status;
  final String title;
  final String description;
  final String location;
  final String city;
  final String date;
  final bool isBoosted;
  final String? imageUrl;
  final List<String> images;
  final int commentsCount;
  final int likesCount;
  final bool likedByMe;
  final bool contactChat;
  final bool contactWhatsApp;
  final bool contactCall;
  final String? ownerPhone;

  ApiListing({
    required this.id,
    required this.ownerId,
    this.ownerName,
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
    required this.commentsCount,
    required this.likesCount,
    required this.likedByMe,
    required this.contactChat,
    required this.contactWhatsApp,
    required this.contactCall,
    required this.ownerPhone,
  });

  factory ApiListing.fromJson(Map<String, dynamic> json) {
    final imgs = (json['images'] is List)
        ? (json['images'] as List).map((e) => e.toString()).toList()
        : <String>[];
    int parseOwnerId() {
      final raw =
          json['owner_id'] ??
          json['ownerId'] ??
          json['user_id'] ??
          json['userId'] ??
          json['id_user'] ??
          json['idUser'];
      return raw is num
          ? raw.toInt()
          : int.tryParse(raw?.toString() ?? '0') ?? 0;
    }

    return ApiListing(
      id: (json['id'] as num).toInt(),
      ownerId: parseOwnerId(),
      ownerName:
          (json['owner_name'] ?? json['user_name'] ?? '')
              .toString()
              .trim()
              .isNotEmpty
          ? (json['owner_name'] ?? json['user_name']).toString()
          : null,
      type: json['type']?.toString() ?? 'lost',
      status: json['status']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? json['city']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      isBoosted:
          json['is_boosted'] == 1 ||
          json['is_boosted'] == true ||
          (json['is_boosted']?.toString() == '1'),
      imageUrl: json['imageUrl']?.toString(),
      images: imgs,
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

class ApiListingComment {
  final int id;
  final int listingId;
  final int? userId;
  final String fullName;
  final String content;
  final String? status;
  final DateTime? createdAt;

  ApiListingComment({
    required this.id,
    required this.listingId,
    required this.userId,
    required this.fullName,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  factory ApiListingComment.fromJson(Map<String, dynamic> json) {
    return ApiListingComment(
      id: (json['id'] ?? 0) is num ? (json['id'] as num).toInt() : 0,
      listingId: (json['listing_id'] ?? 0) is num
          ? (json['listing_id'] as num).toInt()
          : int.tryParse(json['listing_id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] == null
          ? null
          : (json['user_id'] is num
                ? (json['user_id'] as num).toInt()
                : int.tryParse(json['user_id'].toString())),
      fullName: json['full_name']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      status: json['status']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class ApiListingLike {
  final int? userId;
  final int? listingId;
  final String fullName;
  final DateTime? createdAt;

  ApiListingLike({
    this.userId,
    this.listingId,
    required this.fullName,
    this.createdAt,
  });

  factory ApiListingLike.fromJson(Map<String, dynamic> json) {
    return ApiListingLike(
      userId: json['user_id'] == null
          ? null
          : (json['user_id'] is num
                ? (json['user_id'] as num).toInt()
                : int.tryParse(json['user_id'].toString())),
      listingId: json['listing_id'] == null
          ? null
          : (json['listing_id'] is num
                ? (json['listing_id'] as num).toInt()
                : int.tryParse(json['listing_id'].toString())),
      fullName: json['full_name']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class ApiNotification {
  final String type; // like | comment
  final int listingId;
  final String listingTitle;
  final String actorName;
  final String? content;
  final DateTime createdAt;

  ApiNotification({
    required this.type,
    required this.listingId,
    required this.listingTitle,
    required this.actorName,
    required this.createdAt,
    this.content,
  });

  factory ApiNotification.empty() => ApiNotification(
    type: 'like',
    listingId: 0,
    listingTitle: '',
    actorName: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory ApiNotification.fromJson(Map<String, dynamic> json) {
    return ApiNotification(
      type: json['type']?.toString() ?? 'like',
      listingId: int.tryParse(json['listing_id']?.toString() ?? '0') ?? 0,
      listingTitle: json['listing_title']?.toString() ?? '',
      actorName: json['actor_name']?.toString() ?? 'Utilisateur',
      content: json['content']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class NotificationsResult {
  final List<ApiNotification> items;
  final int unreadCount;
  final int page;
  final int perPage;
  final int total;
  final bool hasMore;

  NotificationsResult({
    required this.items,
    required this.unreadCount,
    required this.page,
    required this.perPage,
    required this.total,
    required this.hasMore,
  });
}

class LikeToggleResult {
  final bool liked;
  final int likesCount;
  LikeToggleResult({required this.liked, required this.likesCount});

  factory LikeToggleResult.fromJson(Map<String, dynamic> json) {
    return LikeToggleResult(
      liked: json['liked'] == true || json['liked'] == 1,
      likesCount: json['likes_count'] is num
          ? (json['likes_count'] as num).toInt()
          : int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class ApiAuthRequired implements Exception {
  final String message;
  ApiAuthRequired(this.message);
  @override
  String toString() => message;
}

class ApiPickedImage {
  final XFile file;
  final Uint8List bytes;
  ApiPickedImage({required this.file, required this.bytes});
}

class CreateListingResult {
  final int listingId;
  final bool requiresPayment;
  final int? paymentId;
  final String? amount;
  final String? currency;
  CreateListingResult({
    required this.listingId,
    required this.requiresPayment,
    this.paymentId,
    this.amount,
    this.currency,
  });
}
