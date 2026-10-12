import 'package:flutter/material.dart';

class ShowcaseArt extends StatelessWidget {
  final int variant;
  final double height;

  const ShowcaseArt({super.key, required this.variant, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _ShowcasePainter(variant, Theme.of(context).colorScheme),
    );
  }
}

class _ShowcasePainter extends CustomPainter {
  final int variant;
  final ColorScheme colors;

  _ShowcasePainter(this.variant, this.colors);

  void _rrect(Canvas canvas, Rect rect, double r, Color color) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(r)), Paint()..color = color);
  }

  void _thumbRow(Canvas canvas, double y, double w) {
    final cardW = (w - 32) / 3;
    for (var i = 0; i < 3; i++) {
      final x = 16.0 + i * (cardW + 0) + i * 0;
      final rect = Rect.fromLTWH(x + i * 8, y, cardW - 8, cardW * 0.56);
      _rrect(canvas, rect, 8, colors.surfaceContainerHighest);
      final cx = rect.center.dx;
      final cy = rect.center.dy;
      final tri = Path()
        ..moveTo(cx - 8, cy - 10)
        ..lineTo(cx - 8, cy + 10)
        ..lineTo(cx + 12, cy)
        ..close();
      canvas.drawPath(tri, Paint()..color = colors.primary);
      _rrect(
          canvas,
          Rect.fromLTWH(rect.left + 8, rect.bottom + 6, cardW * 0.55, 8),
          4,
          colors.outlineVariant);
      _rrect(
          canvas,
          Rect.fromLTWH(rect.left + 8, rect.bottom + 18, cardW * 0.35, 6),
          3,
          colors.outlineVariant.withValues(alpha: 0.6));
    }
  }

  void _window(Canvas canvas, Size size, {bool desktop = true}) {
    final w = size.width;
    _rrect(canvas, Offset.zero & size, 16, colors.surfaceContainerHigh);

    if (desktop) {
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
            Offset(20.0 + i * 16, 20), 5,
            Paint()
              ..color = [
                const Color(0xFFFF5F57),
                const Color(0xFFFEBC2E),
                const Color(0xFF28C840)
              ][i]);
      }
      _rrect(canvas, Rect.fromLTWH(w * 0.25, 12, w * 0.5, 16), 8,
          colors.surfaceContainerHighest);
    } else {
      _rrect(canvas, Rect.fromLTWH(w * 0.38, 10, w * 0.24, 8), 4,
          colors.surfaceContainerHighest);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    switch (variant) {
      case 0:
        _window(canvas, size);
        _rrect(canvas, Rect.fromLTWH(16, 44, 48, h - 60), 10,
            colors.surfaceContainerHighest);
        for (var i = 0; i < 4; i++) {
          canvas.drawCircle(Offset(40, 66.0 + i * 34), 8,
              Paint()..color = i == 0 ? colors.primary : colors.outlineVariant);
        }
        _thumbRow(canvas, 52, w - 76);
        _thumbRow(canvas, 52 + h * 0.42, w - 76);
      case 1:
        _window(canvas, size);
        final player = Rect.fromLTWH(16, 44, w * 0.62, h - 60);
        _rrect(canvas, player, 10, Colors.black);
        final cx = player.center.dx;
        final cy = player.center.dy;
        canvas.drawCircle(
            Offset(cx, cy), 26, Paint()..color = colors.primary);
        final tri = Path()
          ..moveTo(cx - 9, cy - 13)
          ..lineTo(cx - 9, cy + 13)
          ..lineTo(cx + 15, cy)
          ..close();
        canvas.drawPath(tri, Paint()..color = Colors.white);
        _rrect(canvas, Rect.fromLTWH(player.left + 16, player.bottom - 22,
            player.width * 0.7, 4), 2, colors.primary);
        canvas.drawCircle(
            Offset(player.left + 16 + player.width * 0.45, player.bottom - 20),
            6,
            Paint()..color = Colors.white);
        for (var i = 0; i < 3; i++) {
          final y = 52.0 + i * (h - 60) / 3;
          _rrect(canvas, Rect.fromLTWH(w * 0.68, y, w * 0.28, (h - 80) / 4), 8,
              colors.surfaceContainerHighest);
          _rrect(canvas, Rect.fromLTWH(w * 0.68, y + (h - 70) / 4, w * 0.2, 7),
              3, colors.outlineVariant);
        }
      case 2:
        _window(canvas, size, desktop: false);
        final padTop = 30.0;
        for (var i = 0; i < 4; i++) {
          final y = padTop + 14 + i * (h - 60) / 4;
          canvas.drawCircle(
              Offset(36, y + 14), 14,
              Paint()..color = i == 1 ? colors.primary : colors.surfaceContainerHighest);
          _rrect(canvas, Rect.fromLTWH(60, y + 6, w * 0.4, 8), 4,
              colors.outlineVariant);
          _rrect(canvas, Rect.fromLTWH(60, y + 18, w * 0.28, 6), 3,
              colors.outlineVariant.withValues(alpha: 0.6));
        }
        _rrect(canvas, Rect.fromLTWH(16, h - 30, w - 32, 18), 9,
            colors.surfaceContainerHighest);
      default:
        _window(canvas, size);
    }
  }

  @override
  bool shouldRepaint(_ShowcasePainter oldDelegate) =>
      oldDelegate.variant != variant;
}
