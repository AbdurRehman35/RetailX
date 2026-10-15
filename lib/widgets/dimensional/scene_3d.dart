import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum Scene3DKind { store, register, package }

/// Lightweight animated isometric “3D” scenes (no GLB needed — works on Flutter web).
class Scene3D extends StatefulWidget {
  const Scene3D({
    super.key,
    required this.kind,
    this.size = 160,
    this.primary = AppTheme.primary,
    this.accent = AppTheme.accent,
  });

  final Scene3DKind kind;
  final double size;
  final Color primary;
  final Color accent;

  @override
  State<Scene3D> createState() => _Scene3DState();
}

class _Scene3DState extends State<Scene3D> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final floatY = math.sin(t * math.pi) * 6;
        final tilt = (t - 0.5) * 0.08;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(0.18 + tilt * 0.3)
              ..rotateY(-0.35 + tilt)
              ..translateByDouble(0.0, floatY, 0.0, 1.0),
            child: CustomPaint(
              painter: _IsoPainter(
                kind: widget.kind,
                primary: widget.primary,
                accent: widget.accent,
                pulse: t,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IsoPainter extends CustomPainter {
  _IsoPainter({
    required this.kind,
    required this.primary,
    required this.accent,
    required this.pulse,
  });

  final Scene3DKind kind;
  final Color primary;
  final Color accent;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 8;

    // Soft ground shadow
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.12 + pulse * 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + size.height * 0.28),
        width: size.width * 0.55,
        height: size.height * 0.12,
      ),
      shadow,
    );

    switch (kind) {
      case Scene3DKind.store:
        _paintStore(canvas, cx, cy, size);
      case Scene3DKind.register:
        _paintRegister(canvas, cx, cy, size);
      case Scene3DKind.package:
        _paintPackage(canvas, cx, cy, size);
    }
  }

  void _paintStore(Canvas canvas, double cx, double cy, Size size) {
    final s = size.width * 0.22;
    final top = Color.lerp(primary, Colors.white, 0.18)!;
    final left = primary;
    final right = Color.lerp(primary, Colors.black, 0.18)!;
    final accentFace = Color.lerp(accent, Colors.white, 0.15)!;

    // Building body
    _drawBox(canvas, Offset(cx, cy), s * 1.6, s * 1.4, s * 1.8, top, left, right);

    // Awning
    _drawBox(
      canvas,
      Offset(cx, cy - s * 0.55),
      s * 1.9,
      s * 0.35,
      s * 0.45,
      accentFace,
      accent,
      Color.lerp(accent, Colors.black, 0.2)!,
    );

    // Door
    final doorPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final door = Path()
      ..moveTo(cx - s * 0.15, cy + s * 0.95)
      ..lineTo(cx + s * 0.25, cy + s * 0.75)
      ..lineTo(cx + s * 0.25, cy + s * 0.15)
      ..lineTo(cx - s * 0.15, cy + s * 0.35)
      ..close();
    canvas.drawPath(door, doorPaint);

    // Window glow
    final window = Paint()..color = accent.withValues(alpha: 0.35 + pulse * 0.25);
    canvas.drawPath(
      Path()
        ..moveTo(cx + s * 0.45, cy + s * 0.15)
        ..lineTo(cx + s * 0.95, cy - s * 0.1)
        ..lineTo(cx + s * 0.95, cy + s * 0.35)
        ..lineTo(cx + s * 0.45, cy + s * 0.6)
        ..close(),
      window,
    );
  }

  void _paintRegister(Canvas canvas, double cx, double cy, Size size) {
    final s = size.width * 0.2;
    final baseTop = Color.lerp(primary, Colors.white, 0.25)!;
    final baseLeft = primary;
    final baseRight = Color.lerp(primary, Colors.black, 0.2)!;

    // Base
    _drawBox(canvas, Offset(cx, cy + s * 0.3), s * 1.8, s * 1.1, s * 0.9, baseTop, baseLeft, baseRight);

    // Screen
    _drawBox(
      canvas,
      Offset(cx - s * 0.15, cy - s * 0.55),
      s * 1.1,
      s * 0.55,
      s * 0.9,
      Color.lerp(accent, Colors.white, 0.45)!,
      accent,
      Color.lerp(accent, Colors.black, 0.25)!,
    );

    // Screen glow
    final glow = Paint()
      ..color = accent.withValues(alpha: 0.2 + pulse * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(cx - s * 0.15, cy - s * 0.7), s * 0.55, glow);

    // Drawer line
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - s * 0.7, cy + s * 0.55),
      Offset(cx + s * 0.7, cy + s * 0.15),
      line,
    );
  }

  void _paintPackage(Canvas canvas, double cx, double cy, Size size) {
    final s = size.width * 0.24;
    final top = const Color(0xFFE8C39E);
    final left = const Color(0xFFD2A679);
    final right = const Color(0xFFB8895A);

    _drawBox(canvas, Offset(cx, cy), s * 1.4, s * 1.4, s * 1.4, top, left, right);

    // Tape
    final tape = Paint()..color = Colors.white.withValues(alpha: 0.7);
    final tapePath = Path()
      ..moveTo(cx - s * 0.15, cy - s * 0.85)
      ..lineTo(cx + s * 0.15, cy - s * 0.95)
      ..lineTo(cx + s * 0.15, cy + s * 0.55)
      ..lineTo(cx - s * 0.15, cy + s * 0.65)
      ..close();
    canvas.drawPath(tapePath, tape);

    // Accent sticker
    final sticker = Paint()..color = accent.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(cx + s * 0.55, cy + s * 0.1), s * 0.18, sticker);
  }

  void _drawBox(
    Canvas canvas,
    Offset center,
    double w,
    double d,
    double h,
    Color top,
    Color left,
    Color right,
  ) {
    // Isometric vectors
    final ox = w * 0.5;
    final oy = d * 0.28;
    final hz = h * 0.55;

    final topC = center.translate(0, -hz * 0.35);
    final pTop = [
      Offset(topC.dx, topC.dy - oy),
      Offset(topC.dx + ox, topC.dy),
      Offset(topC.dx, topC.dy + oy),
      Offset(topC.dx - ox, topC.dy),
    ];
    final pLeft = [
      pTop[3],
      pTop[2],
      Offset(pTop[2].dx, pTop[2].dy + hz),
      Offset(pTop[3].dx, pTop[3].dy + hz),
    ];
    final pRight = [
      pTop[2],
      pTop[1],
      Offset(pTop[1].dx, pTop[1].dy + hz),
      Offset(pTop[2].dx, pTop[2].dy + hz),
    ];

    void face(List<Offset> pts, Color color) {
      final path = Path()..addPolygon(pts, true);
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    face(pLeft, left);
    face(pRight, right);
    face(pTop, top);
  }

  @override
  bool shouldRepaint(covariant _IsoPainter oldDelegate) =>
      oldDelegate.pulse != pulse ||
      oldDelegate.kind != kind ||
      oldDelegate.primary != primary ||
      oldDelegate.accent != accent;
}
