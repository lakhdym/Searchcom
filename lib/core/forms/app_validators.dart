import '../constants/app_messages.dart';

class AppValidators {
  AppValidators._();

  static String? identifier(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return AppMessages.emailOrPhoneRequired();

    final isEmail = trimmed.contains('@');
    final isPhone = trimmed.replaceAll(RegExp(r'\D'), '').length >= 6;
    return (isEmail || isPhone)
        ? null
        : AppMessages.validEmailOrPhoneRequired();
  }

  static String? fullName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return AppMessages.fullNameRequired();
    return trimmed.length >= 2 ? null : AppMessages.fullNameRequired();
  }

  static String? emailOptional(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed.contains('@') ? null : AppMessages.validEmailRequired();
  }

  static String? phoneOptional(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed.replaceAll(RegExp(r'\D'), '').length >= 6
        ? null
        : AppMessages.validPhoneRequired();
  }

  static String? password(String? value) {
    final raw = value ?? '';
    if (raw.isEmpty) return AppMessages.passwordRequired();
    return raw.length >= 8 ? null : AppMessages.passwordMinLength();
  }

  static String? currentPassword(String? value) {
    final raw = value ?? '';
    if (raw.isEmpty) return AppMessages.passwordRequired();
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) return AppMessages.passwordRequired();
    return value == password ? null : AppMessages.passwordMismatch();
  }

  static String? title(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? AppMessages.requiredField() : null;
  }

  static String? description(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? AppMessages.descriptionRequired() : null;
  }

  static String? city(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? AppMessages.cityRequired() : null;
  }

  static String? location(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? AppMessages.requiredField() : null;
  }

  static String? category(int? value) {
    return value == null ? AppMessages.categoryRequired() : null;
  }

  static String? verificationCode(String? value, {int minLength = 6}) {
    final trimmed = value?.trim() ?? '';
    return trimmed.length >= minLength ? null : AppMessages.validCodeRequired();
  }

  static String? comment(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? AppMessages.commentRequired() : null;
  }
}
