import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/theme_context.dart';

enum HoldTone {
  /// On the paper background (Caution, Jaga Pause).
  calm,

  /// On the Warning's red field.
  onWarning,
}

/// Dismiss-by-holding button. The fill sweeps left to right while held; releasing
/// early rewinds it. With TalkBack (accessible navigation) there is no hold: the
/// first activation arms it and announces the confirm hint, a second activation
/// within 5 s confirms.
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.secondLabel,
    this.hold = const Duration(seconds: 2),
    this.tone = HoldTone.calm,
    this.height = 64,
    this.hint,
    this.confirmHint,
  });

  final String label;

  /// Shown instead of [label] while held or armed (e.g. "Keep holding").
  final String? secondLabel;
  final Duration hold;
  final VoidCallback onConfirmed;
  final HoldTone tone;
  final double height;

  /// Semantics hints; default to the shared "Hold for 2 seconds" / "Tap again" copy.
  final String? hint;
  final String? confirmHint;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  static const _armWindow = Duration(seconds: 5);
  static const _rewind = Duration(milliseconds: 200);

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.hold)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _confirm();
        });
  Timer? _armTimer;
  bool _armed = false;

  @override
  void dispose() {
    _armTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    _armTimer?.cancel();
    HapticFeedback.heavyImpact();
    // Reset first so the button is reusable if the host keeps it on screen.
    _controller.value = 0;
    setState(() => _armed = false);
    widget.onConfirmed();
  }

  void _down(PointerDownEvent _) {
    HapticFeedback.selectionClick();
    _controller.forward();
  }

  void _up(PointerEvent _) {
    if (_controller.isCompleted) return;
    final instant = MediaQuery.disableAnimationsOf(context);
    _controller.animateBack(0, duration: instant ? Duration.zero : _rewind);
  }

  void _semanticTap() {
    if (_armed) {
      _confirm();
      return;
    }
    setState(() => _armed = true);
    _armTimer?.cancel();
    _armTimer = Timer(_armWindow, () {
      if (mounted) setState(() => _armed = false);
    });
    final l = AppLocalizations.of(context);
    SemanticsService.sendAnnouncement(
      View.of(context),
      widget.confirmHint ?? l.commonTapAgainHint,
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final c = context.jagaColors;
    final m = context.metrics;
    final (bg, fill, fg, border) = switch (widget.tone) {
      HoldTone.calm => (
          scheme.surface,
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          scheme.outline
        ),
      HoldTone.onWarning => (
          c.warning,
          c.onWarning.withValues(alpha: 0.22),
          c.onWarning,
          c.onWarning
        ),
    };
    final radius = BorderRadius.circular(m.radiusMedium);

    return Semantics(
      button: true,
      label: widget.label,
      hint: _armed
          ? (widget.confirmHint ?? l.commonTapAgainHint)
          : (widget.hint ?? l.commonHoldHint),
      onTap: _semanticTap,
      child: ExcludeSemantics(
        child: Listener(
          onPointerDown: _down,
          onPointerUp: _up,
          onPointerCancel: _up,
          child: Container(
            constraints: BoxConstraints(minHeight: widget.height),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              border: Border.all(color: border, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(m.radiusMedium - 2),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, _) => Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FractionallySizedBox(
                          widthFactor: _controller.value,
                          heightFactor: 1,
                          child: ColoredBox(color: fill),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: m.m, vertical: m.s + m.xs),
                    child: SizedBox(
                      width: double.infinity,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (_, _) {
                          final active = _controller.value > 0 || _armed;
                          return Text(
                            active && widget.secondLabel != null
                                ? widget.secondLabel!
                                : widget.label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: fg),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
