import 'package:flutter/material.dart';

enum JagaWordmarkSize {
  /// Warning masthead.
  large(28),

  /// Caution banner.
  small(22);

  const JagaWordmarkSize(this.fontSize);

  final double fontSize;
}

/// The word "Jaga" as Jaga's signature on a notice. Identity, not content: its
/// own text-scale cap (1.3) and hidden from TalkBack.
class JagaWordmark extends StatelessWidget {
  const JagaWordmark({
    super.key,
    required this.color,
    this.size = JagaWordmarkSize.large,
  });

  final Color color;
  final JagaWordmarkSize size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Text(
          'Jaga',
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.w800,
            fontSize: size.fontSize,
            letterSpacing: -0.5,
            color: color,
          ),
        ),
      ),
    );
  }
}
