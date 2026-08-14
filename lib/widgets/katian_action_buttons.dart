import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Boutons d'action avec icône — usage cohérent dans toute l'app.
class KatianActionButtons {
  KatianActionButtons._();

  static Widget cancel({
    required VoidCallback? onPressed,
    String label = 'Annuler',
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.close, size: 18),
      label: Text(label),
    );
  }

  static Widget no({
    required VoidCallback? onPressed,
    String label = 'Non',
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.close, size: 18),
      label: Text(label),
    );
  }

  static Widget confirm({
    required VoidCallback? onPressed,
    required String label,
    Color? backgroundColor,
    IconData icon = Icons.check,
  }) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: backgroundColor != null
          ? FilledButton.styleFrom(backgroundColor: backgroundColor)
          : null,
    );
  }

  static Widget yes({
    required VoidCallback? onPressed,
    String label = 'Oui',
  }) {
    return confirm(
      onPressed: onPressed,
      label: label,
      backgroundColor: KatianColors.red,
    );
  }

  static Widget outlined({
    required VoidCallback? onPressed,
    required String label,
    IconData icon = Icons.arrow_back,
    ButtonStyle? style,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: style,
    );
  }

  static Widget elevated({
    required VoidCallback? onPressed,
    required String label,
    IconData icon = Icons.check,
    Widget? leading,
    ButtonStyle? style,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: leading ?? Icon(icon, size: 18),
      label: Text(label),
      style: style,
    );
  }

  static Widget text({
    required VoidCallback? onPressed,
    required String label,
    IconData icon = Icons.arrow_forward,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  static Widget filled({
    required VoidCallback? onPressed,
    required String label,
    IconData icon = Icons.check,
    Widget? leading,
    bool loading = false,
    ButtonStyle? style,
  }) {
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : (leading ?? Icon(icon, size: 18)),
      label: Text(label),
      style: style,
    );
  }
}
