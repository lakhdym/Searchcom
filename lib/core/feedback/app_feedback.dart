import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../constants/app_messages.dart';
import '../errors/app_error_mapper.dart';

class AppFeedback {
  AppFeedback._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showSuccessSnackBar(BuildContext? context, String message) {
    _showSnackBar(
      context,
      message,
      backgroundColor: AppTheme.successGreen,
      icon: Icons.check_circle_outline,
    );
  }

  static void showErrorSnackBar(BuildContext? context, String message) {
    _showSnackBar(
      context,
      message,
      backgroundColor: AppTheme.errorRed,
      icon: Icons.error_outline,
    );
  }

  static void showInfoSnackBar(BuildContext? context, String message) {
    _showSnackBar(
      context,
      message,
      backgroundColor: const Color(0xFF2563EB),
      icon: Icons.info_outline,
    );
  }

  static void showMappedErrorSnackBar(
    BuildContext? context,
    Object error, {
    String? fallbackMessage,
  }) {
    showErrorSnackBar(
      context,
      AppErrorMapper.message(
        error,
        fallbackMessage: fallbackMessage ?? AppMessages.genericError(),
      ),
    );
  }

  static void _showSnackBar(
    BuildContext? context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    final messenger = context != null
        ? (ScaffoldMessenger.maybeOf(context) ?? messengerKey.currentState)
        : messengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
