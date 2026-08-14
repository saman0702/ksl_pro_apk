import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

/// Vérifie Play Store / App Store et invite (ou force) la mise à jour.
///
/// Pour imposer une version minimale côté code, passer [minAppVersion]
/// (ex. `'1.0.1'`). En dessous, Ignore / Plus tard sont masqués automatiquement.
Widget wrapWithAppUpgrader(
  Widget child, {
  String? minAppVersion,
}) {
  return UpgradeAlert(
    upgrader: Upgrader(
      languageCode: 'fr',
      messages: UpgraderMessages(code: 'fr'),
      countryCode: 'ci',
      durationUntilAlertAgain: const Duration(days: 1),
      minAppVersion: minAppVersion,
      debugLogging: kDebugMode,
    ),
    showIgnore: false,
    showLater: false,
    barrierDismissible: false,
    shouldPopScope: () => false,
    child: child,
  );
}
