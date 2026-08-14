import 'package:flutter/material.dart';

import '../models/katian_user.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/auth/login_screen.dart';
import 'app_shell.dart';

/// Écran cible après bootstrap (splash) selon l'état session.
Widget destinationAfterBootstrap(KatianUser? user) {
  if (user == null) return const LoginScreen();
  if (user.isConvoyeur && user.mustChangePassword) {
    return const ChangePasswordScreen(required: true, showDefaultHint: true);
  }
  return shellForUser(user);
}

/// Redirige vers le shell ou force le changement de mot de passe convoyeur.
void navigateAfterAuth(
  BuildContext context,
  KatianUser user, {
  String? currentPassword,
}) {
  if (user.isConvoyeur && user.mustChangePassword) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ChangePasswordScreen(
          required: true,
          showDefaultHint: true,
          initialOldPassword: currentPassword,
        ),
      ),
    );
    return;
  }
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => shellForUser(user)),
  );
}
