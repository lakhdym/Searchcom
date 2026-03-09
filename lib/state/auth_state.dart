import 'package:flutter/material.dart';

import '../models/user_model.dart';

/// Utilisateur courant (null si déconnecté).
final ValueNotifier<UserModel?> currentUser = ValueNotifier<UserModel?>(null);

/// Compatibilité avec l'ancien code qui utilisait seulement un booléen.
final ValueNotifier<bool> authState = ValueNotifier<bool>(false);

void loginUser(UserModel user) {
  currentUser.value = user;
  authState.value = true;
}

void logoutUser() {
  currentUser.value = null;
  authState.value = false;
}
