import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import 'api_service.dart';
import 'auth_local_storage.dart';
import '../state/auth_state.dart';
import '../models/listing_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class EmailVerificationRequiredException extends ApiException {
  final String? email;
  final String? phone;
  EmailVerificationRequiredException(String message, {this.email, this.phone, int? statusCode})
      : super(message, statusCode: statusCode);
}

class PhoneVerificationRequiredException extends ApiException {
  final String? phone;
  final String? email;
  PhoneVerificationRequiredException(String message, {this.phone, this.email, int? statusCode})
      : super(message, statusCode: statusCode);
}

class AuthSession {
  final UserModel user;
  final String token;
  AuthSession({required this.user, required this.token});
}

class RegisterResponse {
  final bool success;
  final String message;
  final String? email;
  final String? phone;
  final bool requiresEmailVerification;
  final bool requiresPhoneVerification;
  RegisterResponse({
    required this.success,
    required this.message,
    this.email,
    this.phone,
    this.requiresEmailVerification = false,
    this.requiresPhoneVerification = false,
  });
}

class AuthApiService {
  AuthApiService._();
  static final AuthApiService instance = AuthApiService._();

  final String _baseUrl = ApiService.baseUrlProd;
  final http.Client _client = http.Client();

  // ---------- LOGIN ----------
  Future<AuthSession> login({
    required String identifier, // email OU phone
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/login.php');
    final resp = await _postJson(uri, {
      'identifier': identifier,
      'password': password,
    });
    final status = resp['status'] as int?;
    final success = resp['success'] == true;
    if (!success) {
      if (resp['requires_email_verification'] == true) {
        throw EmailVerificationRequiredException(
          resp['message']?.toString() ?? 'Veuillez vÃ©rifier votre adresse email.',
          email: resp['email']?.toString(),
          phone: resp['phone']?.toString(),
          statusCode: status,
        );
      }
      if (resp['requires_phone_verification'] == true) {
        throw PhoneVerificationRequiredException(
          resp['message']?.toString() ?? 'Veuillez vÃ©rifier votre numÃ©ro.',
          phone: resp['phone']?.toString(),
          email: resp['email']?.toString(),
          statusCode: status,
        );
      }
      throw ApiException(resp['message']?.toString() ?? 'Erreur inconnue', statusCode: status);
    }
    final userJson = resp['user'] as Map<String, dynamic>?;
    if (userJson == null) throw ApiException('RÃ©ponse invalide du serveur', statusCode: status);
    final token = (resp['token'] ?? '').toString();
    return AuthSession(user: UserModel.fromJson(userJson), token: token);
  }

  // ---------- REGISTER ----------
  Future<RegisterResponse> register({
    required String fullName,
    String? email,
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
    if (resp['success'] != true) {
      throw ApiException(resp['message']?.toString() ?? 'Erreur inconnue', statusCode: resp['status']);
    }
    return RegisterResponse(
      success: true,
      message: resp['message']?.toString() ?? 'Compte crÃ©Ã©',
      email: resp['email']?.toString() ?? email,
      phone: resp['phone']?.toString() ?? phone,
      requiresEmailVerification: resp['requires_email_verification'] == true,
      requiresPhoneVerification: resp['requires_phone_verification'] == true,
    );
  }

  // ---------- FORGOT PASSWORD (OTP) ----------
  Future<void> forgotPassword({required String identifier}) async {
    final uri = Uri.parse('$_baseUrl/forgot_password.php');
    final resp = await _postJson(uri, {'identifier': identifier});
    if (resp['success'] != true) {
      throw ApiException(resp['message']?.toString() ?? 'Impossible d\'envoyer le code');
    }
  }

  Future<String> verifyResetOtp({required String identifier, required String otp}) async {
    final uri = Uri.parse('$_baseUrl/verify_otp.php');
    final resp = await _postJson(uri, {
      'identifier': identifier,
      'otp': otp,
    });
    if (resp['success'] != true || resp['reset_token'] == null) {
      throw ApiException(resp['message']?.toString() ?? 'Code invalide', statusCode: resp['status']);
    }
    return resp['reset_token'].toString();
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$_baseUrl/reset_password.php');
    final resp = await _postJson(uri, {
      'token': token,
      'new_password': newPassword,
    });
    if (resp['success'] != true) {
      throw ApiException(resp['message']?.toString() ?? 'Impossible de rÃ©initialiser le mot de passe');
    }
  }

  Future<void> sendPhoneOtp({required String phone}) async {
    final uri = Uri.parse('$_baseUrl/send_phone_verification_code.php');
    final resp = await _postJson(uri, {'phone': phone});
    if (resp['success'] != true) {
      throw ApiException(resp['message']?.toString() ?? 'Envoi impossible', statusCode: resp['status']);
    }
  }

  Future<void> verifyPhoneOtp({required String phone, required String code}) async {
    final uri = Uri.parse('$_baseUrl/verify_phone_code.php');
    final resp = await _postJson(uri, {'phone': phone, 'code': code});
    if (resp['success'] != true) {
      throw ApiException(resp['message']?.toString() ?? 'Code invalide', statusCode: resp['status']);
    }
  }

  Future<void> resendPhoneOtp({required String phone}) => sendPhoneOtp(phone: phone);

  // Email (inchangÃ©)
  Future<void> verifyEmail({required String email, required String code}) async {
    final uri = Uri.parse('$_baseUrl/verify_email.php');
    final resp = await _postJson(uri, {'email': email, 'code': code});
    if (resp['success'] != true) {
      throw ApiException(resp['message']?.toString() ?? 'Code invalide', statusCode: resp['status']);
    }
  }

  Future<void> resendVerification({required String email}) async {
    final uri = Uri.parse('$_baseUrl/resend_verification_code.php');
    final resp = await _postJson(uri, {'email': email});
    if (resp['success'] != true) {
      throw ApiException(resp['message']?.toString() ?? 'Envoi impossible', statusCode: resp['status']);
    }
  }

  // Profile / password (inchangÃ©)
  Future<UserModel> updateProfile({
    required int userId,
    required String fullName,
    required String email,
    String? phone,
    required String preferredLang,
    String? avatarUrl,
  }) async {
    final uri = Uri.parse('$_baseUrl/update_profile.php');
    final resp = await _postJson(uri, {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'preferred_lang': preferredLang,
      'avatar_url': avatarUrl,
    });
    if (resp['success'] != true) {
      throw ApiException(resp['message']?.toString() ?? 'Mise Ã  jour impossible', statusCode: resp['status']);
    }
    final userJson = resp['user'] as Map<String, dynamic>?;
    if (userJson == null) throw ApiException('RÃ©ponse invalide du serveur', statusCode: resp['status']);
    return UserModel.fromJson(userJson);
  }

  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$_baseUrl/change_password.php');
    final resp = await _postJson(uri, {
      'user_id': userId,
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    if (resp['success'] != true) {
      throw ApiException(resp['message']?.toString() ?? 'Impossible de changer le mot de passe', statusCode: resp['status']);
    }
  }

  Future<void> logout() async {
    await AuthLocalStorage.instance.clear();
    logoutUser();
  }

  // Helpers
  Future<Map<String, dynamic>> _postJson(Uri uri, Map<String, dynamic> payload,
      {Map<String, String>? headers}) async {
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ...?headers,
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      // Décodage robuste (évite les soucis d'accents / encodage)
      final decoded = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> data = jsonDecode(decoded) as Map<String, dynamic>;
      data['status'] = response.statusCode;
      return data;
    } on SocketException {
      throw ApiException('Connexion rÃ©seau impossible. VÃ©rifiez votre connexion internet.');
    } on FormatException {
      throw ApiException('RÃ©ponse serveur invalide.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Erreur inconnue: $e');
    }
  }
}

