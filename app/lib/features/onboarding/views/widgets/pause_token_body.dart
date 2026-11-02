import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';

/// The Jaga Pause token, in groups of four, with Copy and Share. Used by the
/// setup step and by settings.
class PauseTokenBody extends StatefulWidget {
  const PauseTokenBody({super.key, required this.token, required this.onShare});

  final String token;
  final ValueChanged<String> onShare;

  /// "JAGA-7Q4M-2KXP-9D3F" reads as "JAGA 7Q4M 2KXP 9D3F".
  static String grouped(String token) {
    final raw = token.replaceAll('-', '');
    return [
      for (var i = 0; i < raw.length; i += 4)
        raw.substring(i, i + 4 > raw.length ? raw.length : i + 4),
    ].join(' ');
  }

  @override
  State<PauseTokenBody> createState() => _PauseTokenBodyState();
}

class _PauseTokenBodyState extends State<PauseTokenBody> {
  Timer? _reset;
  bool _copied = false;

  /// A SnackBar would sit on top of Continue; the Copy button says "Copied" instead.
  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.token));
    _reset?.cancel();
    setState(() => _copied = true);
    _reset = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.onboardingPauseBody, style: text.bodyLarge),
        SizedBox(height: m.l),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(m.m),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(m.radiusSmall),
          ),
          child: SelectableText(
            PauseTokenBody.grouped(widget.token),
            style: text.bodyLarge,
          ),
        ),
        SizedBox(height: m.m),
        Wrap(
          spacing: m.s,
          runSpacing: m.s,
          children: [
            OutlinedButton.icon(
              icon: Icon(_copied ? Icons.check : Icons.copy),
              label: Semantics(
                liveRegion: true,
                child: Text(_copied ? l.commonCopied : l.commonCopy),
              ),
              onPressed: _copy,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.share),
              label: Text(l.commonShare),
              onPressed: () => widget.onShare(widget.token),
            ),
          ],
        ),
      ],
    );
  }
}
