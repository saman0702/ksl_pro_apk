import 'package:flutter/material.dart';

import '../core/katian_theme_extension.dart';

enum KatianFrameBorderStyle { dashed, dotted }

/// Cadre sans fond ni coins arrondis — bordure en tirets ou pointillés.
class KatianDashedFrame extends StatelessWidget {
  const KatianDashedFrame({
    super.key,
    required this.child,
    required this.color,
    this.borderStyle = KatianFrameBorderStyle.dashed,
    this.strokeWidth = 1.5,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color color;
  final KatianFrameBorderStyle borderStyle;
  final double strokeWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashPattern: borderStyle == KatianFrameBorderStyle.dotted
            ? const [2, 4]
            : const [8, 5],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
  });

  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final half = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      half,
      half,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    _drawDashedRect(canvas, rect, paint);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    final sides = [
      Path()..moveTo(rect.left, rect.top)..lineTo(rect.right, rect.top),
      Path()..moveTo(rect.right, rect.top)..lineTo(rect.right, rect.bottom),
      Path()..moveTo(rect.right, rect.bottom)..lineTo(rect.left, rect.bottom),
      Path()..moveTo(rect.left, rect.bottom)..lineTo(rect.left, rect.top),
    ];

    for (final path in sides) {
      for (final metric in path.computeMetrics()) {
        var distance = 0.0;
        var dashIndex = 0;
        while (distance < metric.length) {
          final dash = dashPattern[dashIndex % dashPattern.length];
          final next = distance + dash;
          canvas.drawPath(metric.extractPath(distance, next), paint);
          distance = next + dashPattern[(dashIndex + 1) % dashPattern.length];
          dashIndex += 2;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashPattern != dashPattern;
  }
}

/// Bouton carré hub — bordure tirets, sans badge ni fond plein.
class KatianHubSquareButton extends StatelessWidget {
  const KatianHubSquareButton({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 148,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return KatianDashedFrame(
      color: color,
      borderStyle: KatianFrameBorderStyle.dashed,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 52),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ligne hub — bordure pointillés, icône sans badge coloré.
class KatianHubListRow extends StatelessWidget {
  const KatianHubListRow({
    super.key,
    required this.ext,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final KatianThemeExtension ext;
  final Color accentColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KatianDashedFrame(
      color: accentColor.withValues(alpha: 0.55),
      borderStyle: KatianFrameBorderStyle.dotted,
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Icon(icon, color: accentColor, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ext.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: ext.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: ext.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
