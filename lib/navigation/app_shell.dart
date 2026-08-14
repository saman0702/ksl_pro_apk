import 'package:flutter/material.dart';

import '../models/katian_user.dart';
import '../screens/convoyeur/convoyeur_shell.dart';
import '../screens/main_shell.dart';

Widget shellForUser(KatianUser user) {
  if (user.isConvoyeur) return const ConvoyeurShell();
  return const MainShell();
}
