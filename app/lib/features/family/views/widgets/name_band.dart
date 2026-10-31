import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// The full-bleed field at the top of the family alert: amber for an alert,
/// calm blue for the "may be genuine" follow-up. Cross-fades when the kind changes.
class NameBand extends StatelessWidget {
  const NameBand({
    super.key,
    required this.genuine,
    required this.headline,
    required this.time,
  });

  final bool genuine;
  final String headline;
  final String time;

  @override
  Widget build(BuildContext context) {
    final c = context.jagaColors;
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    final fg = genuine ? c.onGenuineContainer : c.onCaution;
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(m.radiusLarge),
      ),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        width: double.infinity,
        decoration: BoxDecoration(
          color: genuine ? c.genuineContainer : c.caution,
          border: Border(
            bottom: BorderSide(
              color: genuine ? c.genuineContainer : c.cautionEdge,
              width: 3,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.all(m.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (genuine) ...[
                        ExcludeSemantics(
                          child: Icon(
                            Icons.check_circle_outline,
                            size: 32,
                            color: fg,
                          ),
                        ),
                        SizedBox(width: m.s),
                      ],
                      Expanded(
                        child: Text(
                          headline,
                          style: text.headlineMedium?.copyWith(color: fg),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: m.s),
                Text(time, style: text.bodyMedium?.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
