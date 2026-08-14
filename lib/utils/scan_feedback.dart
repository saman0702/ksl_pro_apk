import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Retour sonore + haptique lors d'un scan réussi.
class ScanFeedback {
  ScanFeedback._();

  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  static Future<void> preload() async {
    try {
      await _player.setSource(AssetSource('sounds/scan_beep.wav'));
    } catch (_) {}
  }

  static Future<void> onScanDetected() async {
    await HapticFeedback.mediumImpact();
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/scan_beep.wav'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }
}
