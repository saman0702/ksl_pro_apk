import 'package:flutter/material.dart';

import '../core/katian_theme_extension.dart';

/// Bottom sheet Katian avec fond adapté au thème (clair/sombre).
Future<T?> showKatianWhiteBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  final ext = Theme.of(context).extension<KatianThemeExtension>() ??
      KatianThemeExtension.light;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: Material(
        color: ext.surface,
        surfaceTintColor: Colors.transparent,
        child: builder(ctx),
      ),
    ),
  );
}
