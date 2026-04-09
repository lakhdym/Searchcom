import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'services/api_service.dart';

extension ApiServiceSettingsExtension on ApiService {
  Future<String?> getConditions({String? languageCode}) async {
    final preferredLanguage = _normalizeSupportedLanguage(languageCode);
    final uri = Uri.parse(
      '${ApiService.baseUrlProd}/settings.php',
    ).replace(queryParameters: {'lang': preferredLanguage});

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      final data = _decodeMap(
        utf8.decode(response.bodyBytes, allowMalformed: true),
      );

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(
          _extractErrorMessage(
            data,
            fallback: 'Impossible de charger les conditions d\'utilisation',
          ),
        );
      }

      final payload = data['data'];
      if (payload is Map<String, dynamic>) {
        return _extractLocalizedText(
          payload['conditions'],
          preferredLanguage: preferredLanguage,
        );
      }
      if (payload is Map) {
        final normalizedPayload = Map<String, dynamic>.from(payload);
        return _extractLocalizedText(
          normalizedPayload['conditions'],
          preferredLanguage: preferredLanguage,
        );
      }

      return _extractLocalizedText(
        data['conditions'],
        preferredLanguage: preferredLanguage,
      );
    } on SocketException {
      throw Exception(
        'Connexion reseau impossible. Verifiez votre connexion internet.',
      );
    } on TimeoutException {
      throw Exception('Le chargement des conditions a expire.');
    } on FormatException {
      throw Exception('Reponse serveur invalide.');
    }
  }
}

String _normalizeSupportedLanguage(String? languageCode) {
  switch ((languageCode ?? '').trim().toLowerCase()) {
    case 'ar':
    case 'en':
    case 'fr':
      return (languageCode ?? '').trim().toLowerCase();
    default:
      return 'fr';
  }
}

String? _extractLocalizedText(
  dynamic value, {
  required String preferredLanguage,
}) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  if (value is Map) {
    final normalized = value.map(
      (key, entryValue) =>
          MapEntry(key.toString().toLowerCase(), entryValue?.toString() ?? ''),
    );

    for (final key in [preferredLanguage, 'fr', 'en', 'ar']) {
      final candidate = normalized[key]?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }
  }

  return null;
}

String _extractErrorMessage(
  Map<String, dynamic> data, {
  required String fallback,
}) {
  final message = data['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message;
  }
  return fallback;
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
