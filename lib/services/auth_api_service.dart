import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import 'api_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class AuthApiService {
  AuthApiService._();
  static final AuthApiService instance = AuthApiService._();

  /// URL forcée sur la prod.
  final String _baseUrl = ApiService.baseUrlProd;

  final http.Client _client = http.Client();

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/login.php');
    return _sendAuthRequest(uri, {
      'email': email,
      'password': password,
    });
  }

  Future<RegisterResponse> registerAndRequestVerification({
    required String fullName,
    required String email,
    String? phone,
    required String password,
    String preferredLang = 'fr',
  }) async {
    final uri = Uri.parse('$_baseUrl/register.php');
    final resp = await _postJson(uri, {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'preferred_lang': preferredLang,
    });
    final success = resp['success'] == true;
    if (!success) {
      throw ApiException(resp['message']?.toString() ?? 'Erreur inconnue', statusCode: resp['status']);
    }
    return RegisterResponse(
      success: true,
      message: resp['message']?.toString() ?? 'Compte créé',
      email: resp['email']?.toString() ?? email,
      requiresEmailVerification: resp['requires_email_verification'] == true,
    );
  }

  Future<AuthSession> _sendAuthRequest(Uri uri, Map<String, dynamic> payload) async {
    final resp = await _postJson(uri, payload);
    final status = resp['status'] as int?;
    final success = resp['success'] == true;
    if (!success) {
      if (resp['requires_email_verification'] == true) {
        throw EmailVerificationRequiredException(
          resp['message']?.toString() ?? 'Veuillez vérifier votre adresse email.',
          email: resp['email']?.toString(),
          statusCode: status,
        );
      }
      throw ApiException(resp['message']?.toString() ?? 'Erreur inconnue', statusCode: status);
    }
    final userJson = resp['user'] as Map<String, dynamic>?;
    if (userJson == null) {
      throw ApiException('Réponse invalide du serveur', statusCode: status);
    }
    final token = resp['token'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException('Token d\'authentification manquant', statusCode: status);
    }
    return AuthSession(user: UserModel.fromJson(userJson), token: token);
  }

  Future<Map<String, dynamic>> _postJson(Uri uri, Map<String, dynamic> payload) async {
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      data['status'] = response.statusCode;
      return data;
    } on SocketException {
      throw ApiException('Connexion réseau impossible. Vérifiez votre connexion internet.');
    } on FormatException {
      throw ApiException('Réponse serveur invalide.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Erreur inconnue: $e');
    }
  }

  Future<void> verifyEmail({required String email, required String code}) async {
    final uri = Uri.parse('$_baseUrl/verify_email.php');
    final resp = await _postJson(uri, {'email': email, 'code': code});
    final success = resp['success'] == true;
    if (!success) {
      throw ApiException(resp['message']?.toString() ?? 'Code invalide', statusCode: resp['status']);
    }
  }

  Future<void> resendVerification({required String email}) async {
    final uri = Uri.parse('$_baseUrl/resend_verification_code.php');
    final resp = await _postJson(uri, {'email': email});
    final success = resp['success'] == true;
    if (!success) {
      throw ApiException(resp['message']?.toString() ?? 'Envoi impossible', statusCode: resp['status']);
    }
  }
}

class RegisterResponse {
  final bool success;
  final String message;
  final String email;
  final bool requiresEmailVerification;
  RegisterResponse({
    required this.success,
    required this.message,
    required this.email,
    required this.requiresEmailVerification,
  });
}

class EmailVerificationRequiredException extends ApiException {
  final String? email;
  EmailVerificationRequiredException(String message, {this.email, int? statusCode})
      : super(message, statusCode: statusCode);
}

class AuthSession {
  final UserModel user;
  final String token;
  AuthSession({required this.user, required this.token});
}
