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
    this.wholeWords = false,
  });

  final String text;
  final TextStyle style;
  final double minFontSize;
  final int? maxLines;
  final VoidCallback? onOverflow;

  /// Also steps down until the longest word fits on one line, so no word is
  /// ever split mid-word (CJK has no words to split).
  final bool wholeWords;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final base = DefaultTextStyle.of(context).style.merge(style);
    final startSize = base.fontSize ?? 14;

    return LayoutBuilder(
      builder: (context, constraints) {
        bool wordsFit(double size, double maxWidth) {
          for (final w in RegExp(r'[^\s一-鿿]+').allMatches(text)) {
            final painter = TextPainter(
              text: TextSpan(
                text: w.group(0),
                style: base.copyWith(fontSize: size),
              ),
              textDirection: direction,
              textScaler: scaler,
            )..layout();
            final fits = painter.width <= maxWidth;
            painter.dispose();
            if (!fits) return false;
          }
          return true;
        }

        bool fits(double size) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: base.copyWith(fontSize: size),
            ),
            textDirection: direction,
            textScaler: scaler,
            maxLines: maxLines,
          )..layout(maxWidth: constraints.maxWidth);
          final ok =
              !painter.didExceedMaxLines &&
              (!constraints.hasBoundedHeight ||
                  painter.height <= constraints.maxHeight);
          painter.dispose();
          return ok && (!wholeWords || wordsFit(size, constraints.maxWidth));
        }

        var size = startSize;
        while (size > minFontSize && !fits(size)) {
          size = (size - 2).clamp(minFontSize, startSize);
        }
        if (onOverflow != null && !fits(size)) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onOverflow!());
        }
        return Text(
          text,
          style: style.copyWith(fontSize: size),
          maxLines: maxLines,
        );
      },
    );
  }
}
