import 'package:flutter/material.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/theme_context.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/hold_to_confirm_button.dart';
import '../../core/widgets/reconnecting_dot.dart';
import '../../core/widgets/screen_frame.dart';
import '../../core/widgets/shrink_to_fit_text.dart';
import '../../core/widgets/stage_progress_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/stage.dart';
import '../gallery_entry.dart';

List<GalleryEntry> coreEntries() => [
      for (final tone in BigButtonTone.values)
        GalleryEntry(
          feature: 'core',
          state: 'BigButton ${tone.name}',
          build: (context) => _Pad(
            dark: tone == BigButtonTone.onWarning,
            child: BigButton(
              label: AppLocalizations.of(context).statusProtected,
              icon: Icons.shield_outlined,
              tone: tone,
              onPressed: () {},
            ),
          ),
        ),
      GalleryEntry(
        feature: 'core',
        state: 'HoldToConfirmButton calm',
        build: (context) => _Pad(
          child: HoldToConfirmButton(
              label: AppLocalizations.of(context).statusPauseActive,
              onConfirmed: () {}),
        ),
      ),
      GalleryEntry(
        feature: 'core',
        state: 'HoldToConfirmButton onWarning',
        build: (context) => _Pad(
          dark: true,
          child: HoldToConfirmButton(
              label: AppLocalizations.of(context).statusPauseActive,
              tone: HoldTone.onWarning,
              onConfirmed: () {}),
        ),
      ),
      for (final stage in Stage.values)
        GalleryEntry(
          feature: 'core',
          state: 'StageProgressBar ${stage.name}',
          build: (_) => _Pad(child: StageProgressBar(stage: stage)),
        ),
      GalleryEntry(
        feature: 'core',
        state: 'StageProgressBar compact',
        build: (_) =>
            const _Pad(child: StageProgressBar(stage: Stage.fear, compact: true)),
      ),
      for (final tone in BadgeTone.values)
        GalleryEntry(
          feature: 'core',
          state: 'StatusBadge ${tone.name}',
          build: (context) => _Pad(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusBadge(
                  label: AppLocalizations.of(context).statusProtected,
                  tone: tone,
                  icon: Icons.verified_user_outlined),
            ),
          ),
        ),
      GalleryEntry(
        feature: 'core',
        state: 'ReconnectingDot',
        build: (_) => const _Pad(
          child: Row(children: [
            ReconnectingDot(visible: true),
            ReconnectingDot(visible: false),
          ]),
        ),
      ),
      GalleryEntry(
        feature: 'core',
        state: 'ShrinkToFitText (box 160dp tall)',
        build: (context) => _Pad(
          child: SizedBox(
            height: 160,
            child: ShrinkToFitText(
              text: AppLocalizations.of(context).statusProtected,
              style: context.jagaText.command,
            ),
          ),
        ),
      ),
      GalleryEntry(
        feature: 'core',
        state: 'ScreenFrame',
        build: (context) => ScreenFrame(
          title: AppLocalizations.of(context).appTitle,
          body: StatusBadge(label: AppLocalizations.of(context).statusProtected),
          bottomAction: BigButton(
              label: AppLocalizations.of(context).statusProtected,
              onPressed: () {}),
        ),
      ),
    ];

class _Pad extends StatelessWidget {
  const _Pad({required this.child, this.dark = false});

  final Widget child;

  /// Paints the Warning red behind it, for the on-warning tones.
  final bool dark;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: dark ? context.jagaColors.warning : Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(context.metrics.l),
          child: child,
        ),
      );
}
