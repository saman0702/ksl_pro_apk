import 'package:flutter/material.dart';

import '../core/katian_theme_extension.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'parcel_shipping_photo.dart';

/// Ouvre la photo colis en plein écran (zoom pinch).
void showParcelPhotoFullscreen(BuildContext context, String photoRef) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: SizedBox(
              width: double.infinity,
              height: MediaQuery.sizeOf(ctx).height * 0.75,
              child: ParcelPhotoImage(
                photoRef: photoRef,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Photo du colis mise en avant dans un bottom sheet.
class ParcelSheetHeroImage extends StatelessWidget {
  const ParcelSheetHeroImage({
    super.key,
    required this.parcel,
    this.height = 210,
  });

  final KatianExpedition parcel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ref = parcel.shippingPhotoUrl;
    if (ref == null || ref.isEmpty) return const SizedBox.shrink();

    final ext = context.katian;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => showParcelPhotoFullscreen(context, ref),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: KatianColors.redLight.withValues(alpha: 0.35),
                border: Border.all(color: ext.border),
              ),
              child: ParcelPhotoImage(
                photoRef: ref,
                fit: BoxFit.cover,
                width: double.infinity,
                height: height,
                loadingSize: 28,
                fallback: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: ext.textSecondary,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Appuyez pour agrandir',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: ext.textSecondary),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
