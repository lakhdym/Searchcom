import '../../services/auth_api_service.dart';
import '../constants/app_messages.dart';

class AppErrorMapper {
  AppErrorMapper._();

  static String message(
    Object error, {
    String? fallbackMessage,
    bool allowBackendMessage = true,
  }) {
    if (error is ApiException) {
      return _messageFromApiException(
        error,
        fallbackMessage: fallbackMessage,
        allowBackendMessage: allowBackendMessage,
      );
    }

    final raw = _normalize(error.toString());
    if (raw.isEmpty) {
      return fallbackMessage ?? AppMessages.genericError();
    }

    final status = _extractStatusCode(raw);
    if (status != null) {
      return _messageFromStatusCode(
        status,
        fallbackMessage: fallbackMessage,
        rawMessage: raw,
      );
    }

    if (_looksLikeNetworkError(raw)) {
      return AppMessages.networkError();
    }

    if (_looksUnauthorized(raw)) {
      return AppMessages.sessionExpired();
    }

    if (_looksForbidden(raw)) {
      return AppMessages.accessDenied();
    }

    if (_looksListingNotFound(raw)) {
      return AppMessages.listingNotFound();
    }

    if (_looksConversationNotFound(raw)) {
      return AppMessages.conversationNotFound();
    }

    if (_looksResourceNotFound(raw)) {
      return AppMessages.resourceNotFound();
    }

    if (_looksServerError(raw)) {
      return AppMessages.serverError();
    }

    if (allowBackendMessage && !_looksTechnical(raw)) {
      return raw;
    }

    return fallbackMessage ?? AppMessages.genericError();
  }

  static bool isNotFound(Object error) {
    final raw = _normalize(error.toString());
    final status = _extractStatusCode(raw);
    return status == 404 ||
        _looksListingNotFound(raw) ||
        _looksConversationNotFound(raw) ||
        _looksResourceNotFound(raw);
  }

  static bool isUnauthorized(Object error) {
    final raw = _normalize(error.toString());
    final status = _extractStatusCode(raw);
    return status == 401 || status == 403 || _looksUnauthorized(raw);
  }

  static String _messageFromApiException(
    ApiException error, {
    String? fallbackMessage,
    required bool allowBackendMessage,
  }) {
    final status = error.statusCode;
    final raw = _normalize(error.message);

    if (status != null) {
      return _messageFromStatusCode(
        status,
        fallbackMessage: fallbackMessage,
        rawMessage: raw,
      );
    }

    if (_looksLikeNetworkError(raw)) {
      return AppMessages.networkError();
    }

    if (allowBackendMessage && !_looksTechnical(raw) && raw.isNotEmpty) {
      return raw;
    }

    return fallbackMessage ?? AppMessages.genericError();
  }

  static String _messageFromStatusCode(
    int statusCode, {
    String? fallbackMessage,
    String? rawMessage,
  }) {
    switch (statusCode) {
      case 400:
        return _fallbackOrRaw(
          fallbackMessage,
          rawMessage,
          AppMessages.genericError(),
        );
      case 401:
        return AppMessages.sessionExpired();
      case 403:
        return AppMessages.accessDenied();
      case 404:
        if (rawMessage != null && _looksListingNotFound(rawMessage)) {
          return AppMessages.listingNotFound();
        }
        if (rawMessage != null && _looksConversationNotFound(rawMessage)) {
          return AppMessages.conversationNotFound();
        }
        return AppMessages.resourceNotFound();
      case 500:
      case 502:
      case 503:
      case 504:
        return AppMessages.serverError();
      default:
        return _fallbackOrRaw(
          fallbackMessage,
          rawMessage,
          AppMessages.genericError(),
        );
    }
  }

  static String _fallbackOrRaw(
    String? fallbackMessage,
    String? rawMessage,
    String defaultMessage,
  ) {
    if (fallbackMessage != null && fallbackMessage.trim().isNotEmpty) {
      return fallbackMessage;
    }
    if (rawMessage != null &&
        rawMessage.trim().isNotEmpty &&
        !_looksTechnical(rawMessage)) {
      return rawMessage;
    }
    return defaultMessage;
  }

  static int? _extractStatusCode(String raw) {
    final match = RegExp(r'\b(401|403|404|500|502|503|504)\b').firstMatch(raw);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static bool _looksLikeNetworkError(String raw) {
    final normalized = raw.toLowerCase();
    return normalized.contains('socketexception') ||
        normalized.contains('connexion reseau') ||
        normalized.contains('network') ||
        normalized.contains('timed out') ||
        normalized.contains('timeout') ||
        normalized.contains('failed host lookup');
  }

  static bool _looksUnauthorized(String raw) {
    final normalized = raw.toLowerCase();
    return normalized.contains('token invalide') ||
        normalized.contains('session') ||
        normalized.contains('reconnect') ||
        normalized.contains('non autorise') ||
        normalized.contains('unauthorized');
  }

  static bool _looksForbidden(String raw) {
    final normalized = raw.toLowerCase();
    return normalized.contains('acces refuse') ||
        normalized.contains('forbidden');
  }

  static bool _looksListingNotFound(String raw) {
    final normalized = raw.toLowerCase();
    return normalized.contains('annonce introuvable') ||
        normalized.contains('listing not found');
  }

  static bool _looksConversationNotFound(String raw) {
    final normalized = raw.toLowerCase();
    return normalized.contains('conversation introuvable') ||
        normalized.contains('conversation not found');
  }

  static bool _looksResourceNotFound(String raw) {
    final normalized = raw.toLowerCase();
    return normalized.contains('introuvable') ||
        normalized.contains('not found') ||
        normalized.contains('ressource');
  }

  static bool _looksServerError(String raw) {
    final normalized = raw.toLowerCase();
    return normalized.contains('server error') ||
        normalized.contains('erreur serveur') ||
        normalized.contains('sql') ||
        normalized.contains('pdoexception');
  }

  static bool _looksTechnical(String raw) {
    final normalized = raw.toLowerCase();
    return normalized.contains('exception') ||
        normalized.contains('{') ||
        normalized.contains('stacktrace') ||
        normalized.contains('typeerror') ||
        normalized.contains('formatexception') ||
        normalized.contains('clientexception') ||
        normalized.contains('html>');
  }

  static String _normalize(String raw) {
    var result = raw.trim();
    if (result.startsWith('Exception:')) {
      result = result.substring('Exception:'.length).trim();
    }
    return result;
  }
}
