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

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/login.php');
    return _sendAuthRequest(uri, {
      'email': email,
      'password': password,
    });
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    String? phone,
    required String password,
    String preferredLang = 'fr',
  }) async {
    final uri = Uri.parse('$_baseUrl/register.php');
    return _sendAuthRequest(uri, {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'preferred_lang': preferredLang,
    });
  }

  Future<UserModel> _sendAuthRequest(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      final status = response.statusCode;
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final success = data['success'] == true;
      if (!success) {
        throw ApiException(data['message']?.toString() ?? 'Erreur inconnue', statusCode: status);
      }
      final userJson = data['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        throw ApiException('Réponse invalide du serveur', statusCode: status);
      }
      return UserModel.fromJson(userJson);
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
}
