import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';

/// Avatar réseau ou initiales — logo point relais / gérant (comme le web).
class KatianAvatar extends StatelessWidget {
  const KatianAvatar({
    super.key,
    required this.imageUrl,
    required this.initial,
    this.size = 36,
    this.backgroundColor,
  });

  final String? imageUrl;
  final String initial;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final resolved = AppConfig.resolveMediaUrl(imageUrl);
    final bg = backgroundColor ?? KatianColors.white;

    if (resolved != null && resolved.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          resolved,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(bg),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return _fallback(bg);
          },
        ),
      );
    }

    return _fallback(bg);
  }

  Widget _fallback(Color bg) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial.isNotEmpty ? initial[0].toUpperCase() : 'K',
        style: TextStyle(
          color: KatianColors.red,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
