import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Overlay visuel de scan : masque sombre, cadre, coins et ligne laser animée.
class ScannerOverlay extends StatefulWidget {
  const ScannerOverlay({
    super.key,
    this.scanSize = 240,
    this.active = true,
    this.borderColor = KatianColors.red,
  });

  final double scanSize;
  final bool active;
  final Color borderColor;

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ScannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final scanRect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: widget.scanSize,
          height: widget.scanSize,
        );

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: size,
              painter: _ScannerOverlayPainter(
                scanRect: scanRect,
                borderColor: widget.borderColor,
                laserProgress: widget.active ? _controller.value : 0,
                showLaser: widget.active,
              ),
            );
          },
        );
      },
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({
    required this.scanRect,
    required this.borderColor,
    required this.laserProgress,
    required this.showLaser,
  });

  final Rect scanRect;
  final Color borderColor;
  final double laserProgress;
  final bool showLaser;

  static const _cornerLen = 28.0;
  static const _cornerStroke = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(scanRect, const Radius.circular(16));

    final maskPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect);
    canvas.drawPath(
      maskPath,
      Paint()..color = Colors.black.withValues(alpha: 0.58),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _drawCorner(canvas, scanRect.topLeft, 1, 1);
    _drawCorner(canvas, scanRect.topRight, -1, 1);
    _drawCorner(canvas, scanRect.bottomLeft, 1, -1);
    _drawCorner(canvas, scanRect.bottomRight, -1, -1);

    if (showLaser) {
      final y = scanRect.top + 12 + (scanRect.height - 24) * laserProgress;
      final laserRect = Rect.fromLTWH(
        scanRect.left + 10,
        y,
        scanRect.width - 20,
        2,
      );

      canvas.drawRect(
        laserRect.inflate(3),
        Paint()
          ..color = borderColor.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawRect(
        laserRect,
        Paint()..color = borderColor,
      );
    }
  }

  void _drawCorner(Canvas canvas, Offset origin, int dx, int dy) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerStroke
      ..strokeCap = StrokeCap.round;

    final hEnd = Offset(origin.dx + _cornerLen * dx, origin.dy);
    final vEnd = Offset(origin.dx, origin.dy + _cornerLen * dy);
    canvas.drawLine(origin, hEnd, paint);
    canvas.drawLine(origin, vEnd, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.laserProgress != laserProgress ||
        oldDelegate.showLaser != showLaser ||
        oldDelegate.scanRect != scanRect;
  }
}
