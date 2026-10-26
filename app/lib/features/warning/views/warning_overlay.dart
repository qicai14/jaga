import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../view_models/warning_view_model.dart';
import 'widgets/caution_banner.dart';
import 'widgets/warning_screen.dart';

/// Lays the Caution banner or the Warning over [child] (the call screen).
class WarningOverlay extends StatefulWidget {
  const WarningOverlay({
    super.key,
    required this.vm,
    required this.child,
    required this.onHangUp,
  });

  final WarningViewModel vm;
  final Widget child;
  final VoidCallback onHangUp;

  @override
  State<WarningOverlay> createState() => _WarningOverlayState();
}

class _WarningOverlayState extends State<WarningOverlay> {
  // What TalkBack was last told, so it hears each command once.
  String? _announced;

  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_announce);
  }

  @override
  void didUpdateWidget(WarningOverlay old) {
    super.didUpdateWidget(old);
    if (old.vm != widget.vm) {
      old.vm.removeListener(_announce);
      widget.vm.addListener(_announce);
    }
  }

  @override
  void dispose() {
    widget.vm.removeListener(_announce);
    super.dispose();
  }

  /// "command. English" as a live announcement when the Warning appears or its command changes.
  void _announce() {
    final s = widget.vm.state;
    if (s.layer != WarningLayer.warning) {
      _announced = null;
      return;
    }
    final fallback = AppLocalizations.of(context).warningCommandFallback;
    final command = s.content.command ?? fallback;
    final english = s.content.commandEnglish;
    final spoken =
        english == null || english == command || s.content.command == null
        ? command
        : '$command. $english';
    if (spoken == _announced) return;
    _announced = spoken;
    SemanticsService.sendAnnouncement(
      View.of(context),
      spoken,
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final s = widget.vm.state;
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (s.layer == WarningLayer.caution)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CautionBanner(
                  reconnecting: s.reconnecting,
                  onDismiss: widget.vm.dismiss,
                ),
              ),
            if (s.layer == WarningLayer.warning)
              Positioned.fill(
                // Any touch on the Warning ends the buzz.
                child: Listener(
                  onPointerDown: (_) => widget.vm.stopBuzz(),
                  child: WarningScreen(
                    content: s.content,
                    reconnecting: s.reconnecting,
                    onHangUp: widget.onHangUp,
                    onDismiss: widget.vm.dismiss,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
