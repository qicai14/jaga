import 'package:flutter/material.dart';

/// Text that must fit its box without scrolling. Steps the font size down 2sp at
/// a time (measured with the ambient `TextScaler`) until it fits, never below
/// [minFontSize]. At the floor it clips nothing and calls [onOverflow] so the
/// parent can scroll instead.
class ShrinkToFitText extends StatelessWidget {
  const ShrinkToFitText({
    super.key,
    required this.text,
    required this.style,
    this.minFontSize = 32,
    this.maxLines,
    this.onOverflow,
  });

  final String text;
  final TextStyle style;
  final double minFontSize;
  final int? maxLines;
  final VoidCallback? onOverflow;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final base = DefaultTextStyle.of(context).style.merge(style);
    final startSize = base.fontSize ?? 14;

    return LayoutBuilder(builder: (context, constraints) {
      bool fits(double size) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: base.copyWith(fontSize: size)),
          textDirection: direction,
          textScaler: scaler,
          maxLines: maxLines,
        )..layout(maxWidth: constraints.maxWidth);
        final ok = !painter.didExceedMaxLines &&
            (!constraints.hasBoundedHeight || painter.height <= constraints.maxHeight);
        painter.dispose();
        return ok;
      }

      var size = startSize;
      while (size > minFontSize && !fits(size)) {
        size = (size - 2).clamp(minFontSize, startSize);
      }
      if (onOverflow != null && !fits(size)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onOverflow!());
      }
      return Text(text, style: style.copyWith(fontSize: size), maxLines: maxLines);
    });
  }
}
