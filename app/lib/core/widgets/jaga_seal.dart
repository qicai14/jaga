import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// The launcher icon as a letterhead seal: a `guarded` rounded square with the
/// paper shield and the teal J (`design/launcher-icon.md` section 2). Drawn in
/// code, fixed size (not text-scaled), hidden from TalkBack.
class JagaSeal extends StatelessWidget {
  const JagaSeal({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.jagaColors;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _SealPainter(
          teal: c.guarded,
          paper: Theme.of(context).colorScheme.surface,
          radius: context.metrics.radiusSmall,
        ),
      ),
    );
  }
}

class _SealPainter extends CustomPainter {
  const _SealPainter({
    required this.teal,
    required this.paper,
    required this.radius,
  });

  final Color teal;
  final Color paper;
  final double radius;

  // The notification glyph's shield, in the 24-unit space of the icon.
  static Path _shield() => Path()
    ..moveTo(12, 1)
    ..lineTo(3, 5)
    ..lineTo(3, 11)
    ..cubicTo(3, 16.55, 6.84, 21.74, 12, 23)
    ..cubicTo(17.16, 21.74, 21, 16.55, 21, 11)
    ..lineTo(21, 5)
    ..close();

  // The J as a filled outline: stem 13.7 to 16.3, semicircle bowl.
  static Path _j() => Path()
    ..moveTo(13.7, 6)
    ..lineTo(16.3, 6)
    ..lineTo(16.3, 13)
    ..arcToPoint(const Offset(7.2, 13), radius: const Radius.circular(4.55))
    ..lineTo(9.8, 13)
    ..arcToPoint(
      const Offset(13.7, 13),
      radius: const Radius.circular(1.95),
      clockwise: false,
    )
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      Paint()..color = teal,
    );
    // The shield's box (3..21 x 1..23) is about 20 x 24dp in the 48dp tile;
    // (12, 12) is its centre.
    final scale = size.height / 2 / 11;
    final matrix = Matrix4.identity()
      ..translateByDouble(size.width / 2, size.height / 2, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-12, -12, 0, 1);
    canvas
      ..drawPath(_shield().transform(matrix.storage), Paint()..color = paper)
      ..drawPath(_j().transform(matrix.storage), Paint()..color = teal);
  }

  @override
  bool shouldRepaint(_SealPainter old) =>
      old.teal != teal || old.paper != paper || old.radius != radius;
}
