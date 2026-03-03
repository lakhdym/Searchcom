import 'package:flutter/material.dart';

/// Etat d'authentification simulé (UI only).
/// true => connecté, false => non connecté.
final ValueNotifier<bool> authState = ValueNotifier<bool>(false);
