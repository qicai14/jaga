import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/guarded_masthead.dart';
import '../../../data/models/call_snapshot.dart';
import '../../warning/view_models/warning_view_model.dart';
import '../../warning/views/warning_overlay.dart';
import '../view_models/in_call_view_model.dart';
import 'widgets/call_toggle.dart';

/// The Jaga line call, after she answered on the phone's own call screen (call.md).
/// Leaves by itself when the call is gone: at once if there is none, 3 s after it ended.
class InCallScreen extends StatefulWidget {
  const InCallScreen({super.key, required this.vm, required this.warningVm});

  final InCallViewModel vm;
  final WarningViewModel warningVm;

  /// How long "Call ended" stays before the screen leaves.
  static const endedStay = Duration(seconds: 3);

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> {
  Timer? _leave;
  bool? _announcedMuted;

  InCallViewModel get vm => widget.vm;

  @override
  void initState() {
    super.initState();
    vm.addListener(_onChange);
    _announcedMuted = vm.muted;
    WidgetsBinding.instance.addPostFrameCallback((_) => _onChange());
  }

  @override
  void dispose() {
    vm.removeListener(_onChange);
    _leave?.cancel();
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    switch (vm.phase) {
      case CallPhase.idle:
      case CallPhase.ringing:
        _pop();
      case CallPhase.ended:
        _leave ??= Timer(InCallScreen.endedStay, () {
          // A new call may have started in the meantime.
          if (vm.phase == CallPhase.ended) _pop();
        });
      default:
        break;
    }
    if (vm.muted != _announcedMuted) {
      _announcedMuted = vm.muted;
      final l = AppLocalizations.of(context);
      SemanticsService.sendAnnouncement(
        View.of(context),
        vm.muted ? l.callMuted : l.callUnmuted,
        Directionality.of(context),
      );
    }
  }

  // pop, not maybePop: this screen's own PopScope would swallow it.
  void _pop() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  /// Back sends Jaga to the background and the call goes on; nothing while the
  /// Warning is up; after the call it leaves.
  void _back() {
    if (widget.warningVm.state.layer == WarningLayer.warning) return;
    if (vm.phase == CallPhase.ended || vm.phase == CallPhase.failed) {
      _pop();
    } else {
      vm.moveToBack();
    }
  }

  static String _mmss(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final c = context.jagaColors;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: WarningOverlay(
        vm: widget.warningVm,
        onHangUp: vm.hangUp,
        child: Material(
          color: scheme.surface,
          child: ListenableBuilder(
            listenable: Listenable.merge([vm, widget.warningVm]),
            builder: (context, _) {
              final over =
                  vm.phase == CallPhase.ended || vm.phase == CallPhase.failed;
              final failed = vm.phase == CallPhase.failed;
              final time = _mmss(vm.elapsed);
              final status = switch (vm.phase) {
                CallPhase.connecting => l.callConnecting,
                CallPhase.reconnecting => l.callReconnectingAudio,
                CallPhase.ended => '${l.callEnded}  $time',
                CallPhase.failed => l.callFailed,
                _ => time,
              };
              return Column(
                children: [
                  GuardedMasthead(
                    title: l.callProtecting,
                    reconnecting: widget.warningVm.state.reconnecting,
                  ),
                  if (vm.muted && !over)
                    Semantics(
                      button: true,
                      child: InkWell(
                        onTap: vm.toggleMute,
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(minHeight: m.minTarget),
                          color: c.warning,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.symmetric(
                            horizontal: m.l,
                            vertical: m.s,
                          ),
                          child: Text(
                            l.callMuted,
                            style: text.titleMedium?.copyWith(
                              color: c.onWarning,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Caller and status at the top, Mute and Speaker above Hang up;
                  // at huge text this part scrolls and Hang up stays put.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(m.l, m.xl, m.l, m.m),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: box.maxHeight - m.xl - m.m,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _info(context, status, time, failed),
                              if (!over) ...[
                                SizedBox(height: m.l),
                                CallToggle(
                                  icon: vm.muted ? Icons.mic_off : Icons.mic,
                                  label: vm.muted ? l.callMuted : l.callMute,
                                  trailing: vm.muted ? '' : l.callMuteOff,
                                  on: vm.muted,
                                  alarm: true,
                                  onPressed: vm.controlsEnabled
                                      ? vm.toggleMute
                                      : null,
                                ),
                                SizedBox(height: m.m),
                                CallToggle(
                                  icon: Icons.volume_up,
                                  label: l.callSpeaker,
                                  trailing: vm.speakerOn
                                      ? l.callSpeakerOn
                                      : l.callSpeakerOff,
                                  on: vm.speakerOn,
                                  onPressed: vm.controlsEnabled
                                      ? vm.toggleSpeaker
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(m.l, 0, m.l, m.m),
                      child: over
                          ? BigButton(
                              label: l.callDone,
                              onPressed: _pop,
                              maxTextScale: 1.5,
                            )
                          : BigButton(
                              tone: BigButtonTone.hangUp,
                              icon: Icons.call_end,
                              label: l.callHangUp,
                              maxTextScale: 1.5,
                              onPressed: vm.hangUp,
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _info(BuildContext context, String status, String time, bool failed) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    const tabular = [FontFeature.tabularFigures()];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            vm.call.callerLabel ?? l.callUnknownCaller,
            maxLines: 1,
            style: text.headlineMedium?.copyWith(
              color: scheme.onSurface,
              fontFeatures: tabular,
            ),
          ),
        ),
        SizedBox(height: m.s),
        Semantics(
          liveRegion: true,
          child: Text(
            status,
            semanticsLabel: vm.phase == CallPhase.active
                ? l.callTimerSemantics(time)
                : null,
            style: text.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontFeatures: tabular,
            ),
          ),
        ),
        if (failed) ...[
          SizedBox(height: m.s),
          Text(
            l.callFailedBody,
            style: text.bodyLarge?.copyWith(color: scheme.onSurface),
          ),
        ],
      ],
    );
  }
}
