import 'package:flutter/material.dart';

import '../core/katian_theme_extension.dart';
import '../core/theme.dart';

/// Barre de titre compacte pour les wizards imbriqués (onglet Colis, etc.).
class KatianFlowBar extends StatelessWidget {
  const KatianFlowBar({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  static const double height = 40;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Material(
      color: ext.surface,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ext.border.withValues(alpha: 0.65)),
          ),
        ),
        padding: const EdgeInsets.only(right: 12),
        child: Row(
          children: [
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(KatianTheme.buttonBorderRadius),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: ext.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ext.textPrimary,
                  height: 1.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
