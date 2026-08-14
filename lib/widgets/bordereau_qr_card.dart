import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/katian_theme_extension.dart';
import '../core/theme.dart';

/// Carte QR du numéro de bordereau (scan réception gare).
class BordereauQrCard extends StatelessWidget {
  const BordereauQrCard({
    super.key,
    required this.number,
    this.subtitle,
  });

  final String number;
  final String? subtitle;

  Future<void> _copyNumber(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: number));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Numéro de bordereau copié'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'QR code bordereau',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: ext.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: ext.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KatianColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ext.border),
              ),
              child: QrImageView(
                data: number,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: KatianColors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: KatianColors.darkText,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: KatianColors.darkText,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              number,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: KatianColors.red,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _copyNumber(context),
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copier le numéro'),
            ),
          ],
        ),
      ),
    );
  }
}
