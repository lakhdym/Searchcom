import 'dart:convert';

import 'package:http/http.dart' as http;

import 'services/api_service.dart';
import 'services/auth_local_storage.dart';

extension CommentApiExtension on ApiService {
  Future<ApiListingComment> updateComment({
    required int commentId,
    required String content,
  }) async {
    await syncStoredAuthSession();
    if (!isAuthenticated) throw ApiAuthRequired('User not authenticated');

    final uri = Uri.parse('${ApiService.baseUrlProd}/update_comment.php');
    final headers = await _headers(withAuth: true);
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'comment_id': commentId, 'content': content}),
    );

    final data = _decodeMap(response);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        _extractMessage(
          data,
          fallback: 'Impossible de modifier le commentaire',
        ),
      );
    }

    final payload = data['comment'];
    if (payload is Map<String, dynamic>) {
      return ApiListingComment.fromJson(payload);
    }
    if (payload is Map) {
      return ApiListingComment.fromJson(Map<String, dynamic>.from(payload));
    }
    throw Exception('Reponse modification commentaire invalide');
  }

  Future<ApiListingComment> deleteComment({required int commentId}) async {
    await syncStoredAuthSession();
    if (!isAuthenticated) throw ApiAuthRequired('User not authenticated');

    final uri = Uri.parse('${ApiService.baseUrlProd}/delete_comment.php');
    final headers = await _headers(withAuth: true);
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'comment_id': commentId}),
    );

    final data = _decodeMap(response);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        _extractMessage(
          data,
          fallback: 'Impossible de supprimer le commentaire',
        ),
      );
    }

    final payload = data['comment'];
    if (payload is Map<String, dynamic>) {
      return ApiListingComment.fromJson(payload);
    }
    if (payload is Map) {
      return ApiListingComment.fromJson(Map<String, dynamic>.from(payload));
    }
    throw Exception('Reponse suppression commentaire invalide');
  }

  Future<void> reportComment({
    required int commentId,
    required String reason,
    String? details,
  }) async {
    await syncStoredAuthSession();
    if (!isAuthenticated) throw ApiAuthRequired('User not authenticated');

    final uri = Uri.parse('${ApiService.baseUrlProd}/report_comment.php');
    final headers = await _headers(withAuth: true);
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'comment_id': commentId,
        'reason': reason,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      }),
    );

    final data = _decodeMap(response);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        _extractMessage(
          data,
          fallback: 'Impossible de signaler le commentaire',
        ),
      );
    }
  }
}

Future<Map<String, String>> _headers({required bool withAuth}) async {
  final headers = <String, String>{'Content-Type': 'application/json'};
  final token = withAuth ? await AuthLocalStorage.instance.getToken() : null;
  if (withAuth && token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
}

Map<String, dynamic> _decodeMap(http.Response response) {
  final source = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
  if (source.isEmpty) {
    return <String, dynamic>{};
  }

  try {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
  } catch (_) {
    return <String, dynamic>{'message': source};
  }

  return <String, dynamic>{'message': source};
}

String _extractMessage(Map<String, dynamic> data, {required String fallback}) {
  final message = data['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message;
  }
  return fallback;
}
