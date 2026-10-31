import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import 'jaga_wordmark.dart';
import 'reconnecting_dot.dart';

/// The deep teal band under the status bar: wordmark and a short title. The call
/// screen and the Warning share it, so a Warning reads as the same notice unfolding.
class GuardedMasthead extends StatelessWidget {
  const GuardedMasthead({
    super.key,
    required this.title,
    this.reconnecting = false,
  });

  final String title;

  /// The stage stream dropped: the silent dot.
  final bool reconnecting;

  @override
  Widget build(BuildContext context) {
    final c = context.jagaColors;
    final m = context.metrics;
    return Semantics(
      header: true,
      child: ColoredBox(
        color: c.guarded,
        child: SafeArea(
          bottom: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: EdgeInsets.only(left: m.l, right: m.s),
              child: Row(
                children: [
                  Expanded(
                    child: ExcludeSemantics(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          JagaWordmark(color: c.onGuarded),
                          SizedBox(width: m.m),
                          Expanded(
                            child: MediaQuery.withClampedTextScaling(
                              maxScaleFactor: 1.5,
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: c.onGuarded),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ReconnectingDot(visible: reconnecting, color: c.onGuarded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
