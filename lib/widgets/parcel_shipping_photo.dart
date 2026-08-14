import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/katian_theme_extension.dart';
import '../core/theme.dart';

/// Image colis (`img_en_lenvoi`) — URL, chemin relatif ou base64.
class ParcelPhotoImage extends StatelessWidget {
  const ParcelPhotoImage({
    super.key,
    required this.photoRef,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.loadingSize = 18,
    this.fallback,
  });

  final String? photoRef;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double loadingSize;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final ref = photoRef?.trim();
    if (ref == null || ref.isEmpty) {
      return fallback ?? const SizedBox.shrink();
    }

    if (ref.startsWith('data:image')) {
      try {
        final b64 = ref.split(',').last;
        return Image.memory(
          base64Decode(b64),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
        );
      } catch (_) {
        return fallback ?? const SizedBox.shrink();
      }
    }

    final url = AppConfig.resolveMediaUrl(ref);
    if (url == null) return fallback ?? const SizedBox.shrink();

    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: loadingSize,
            height: loadingSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: KatianColors.red.withValues(alpha: 0.7),
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
    );
  }
}

/// Aperçu de la photo du colis (`img_en_lenvoi`).
class ParcelShippingPhoto extends StatelessWidget {
  const ParcelShippingPhoto({
    super.key,
    required this.photoRef,
    this.height = 180,
  });

  final String? photoRef;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ref = photoRef?.trim();
    if (ref == null || ref.isEmpty) return const SizedBox.shrink();

    final ext = context.katian;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.photo_camera_outlined, size: 18, color: ext.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Photo du colis',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ext.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => showParcelPhotoFullscreen(context, ref),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: ext.border.withValues(alpha: 0.35),
                border: Border.all(color: ext.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildImage(ref, ext),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Appuyez pour agrandir',
          style: TextStyle(fontSize: 11, color: ext.textSecondary),
        ),
      ],
    );
  }

  Widget _buildImage(String ref, KatianThemeExtension ext) {
    return ParcelPhotoImage(
      photoRef: ref,
      fit: BoxFit.cover,
      width: double.infinity,
      fallback: _placeholder(ext),
    );
  }

  Widget _placeholder(KatianThemeExtension ext) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: ext.textSecondary, size: 32),
          const SizedBox(height: 6),
          Text(
            'Photo indisponible',
            style: TextStyle(fontSize: 12, color: ext.textSecondary),
          ),
        ],
      ),
    );
  }
}

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
