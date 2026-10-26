import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/haptics/buzzer.dart';
import '../../../data/models/stage.dart';
import '../../../data/models/stage_update.dart';
import '../../../data/repositories/call_risk_repository.dart';
import '../../../data/services/attention_service.dart';

enum WarningLayer { none, caution, warning }

/// What the Warning shows. All text is phrase-library text from the server.
@immutable
class WarningContent {
  const WarningContent({
    this.command,
    this.commandEnglish,
    this.counterMove,
    this.counterMoveEnglish,
    this.officialNumber,
    this.agency,
    this.evidence = const [],
    this.isCredentials = false,
  });

  factory WarningContent.from(StageUpdate u) => WarningContent(
    command: u.command,
    commandEnglish: u.commandEnglish,
    counterMove: u.counterMove,
    counterMoveEnglish: u.counterMoveEnglish,
    officialNumber: u.officialNumber,
    agency: u.claimedAgency,
    evidence: u.evidence,
    isCredentials: u.stage == Stage.credentials,
  );

  /// Null at high means the view shows the built-in safety-net command.
  final String? command;
  final String? commandEnglish;
  final String? counterMove;
  final String? counterMoveEnglish;
  final String? officialNumber;
  final String? agency;
  final List<String> evidence;
  final bool isCredentials;
}

@immutable
class WarningState {
  const WarningState({
    this.layer = WarningLayer.none,
    this.content = const WarningContent(),
    this.reconnecting = false,
  });

  final WarningLayer layer;
  final WarningContent content;
  final bool reconnecting;

  WarningState copyWith({
    WarningLayer? layer,
    WarningContent? content,
    bool? reconnecting,
  }) => WarningState(
    layer: layer ?? this.layer,
    content: content ?? this.content,
    reconnecting: reconnecting ?? this.reconnecting,
  );
}

/// The rules of warning.md section 2. Dismiss is local: nothing here writes to
/// the stream, the family alerts or Jaga Pause.
class WarningViewModel extends ChangeNotifier {
  WarningViewModel({
    required CallRiskRepository repository,
    required Buzzer buzzer,
    required AttentionService attention,
  }) : _repository = repository,
       // ignore: prefer_initializing_formals
       _buzzer = buzzer {
    _subs = [
      repository.updates.listen(_onUpdate),
      attention.looked.listen((_) => stopBuzz()),
    ];
    repository.connected.addListener(_onConnection);
  }

  final CallRiskRepository _repository;
  final Buzzer _buzzer;
  late final List<StreamSubscription<void>> _subs;

  WarningState _state = const WarningState();
  WarningState get state => _state;

  String? _callId;
  bool _dismissed = false;
  Stage? _lastStage;
  Risk? _lastRisk;

  /// Latest update that arrived while the stream was down.
  StageUpdate? _pending;

  /// Hold-to-dismiss confirmed: hide the layer on this phone only.
  void dismiss() {
    if (_state.layer == WarningLayer.none) return;
    _dismissed = true;
    _buzzer.stop();
    _set(_state.copyWith(layer: WarningLayer.none));
  }

  /// A touch on the Warning, or she looked at the phone: the buzz has done its job.
  void stopBuzz() => _buzzer.stop();

  /// Call ended: forget everything.
  void reset() {
    _callId = null;
    _dismissed = false;
    _lastStage = null;
    _lastRisk = null;
    _pending = null;
    if (_state.layer == WarningLayer.warning) _buzzer.stop();
    _set(WarningState(reconnecting: _state.reconnecting));
  }

  void _onConnection() {
    final down = !_repository.connected.value;
    _set(_state.copyWith(reconnecting: down));
    final pending = _pending;
    if (!down && pending != null) {
      _pending = null;
      _apply(pending);
    }
  }

  void _onUpdate(StageUpdate u) {
    if (!_repository.connected.value) {
      _pending = u; // layer and content stay frozen until the stream is back
      return;
    }
    _apply(u);
  }

  void _apply(StageUpdate u) {
    if (u.callId != _callId) {
      reset();
      _callId = u.callId;
    }
    final before = _state;
    final lastRisk = _lastRisk;
    if (_dismissed &&
        lastRisk != null &&
        (u.stage != _lastStage || u.risk.index > lastRisk.index)) {
      _dismissed = false;
    }
    _lastStage = u.stage;
    _lastRisk = u.risk;

    final layer = _dismissed
        ? WarningLayer.none
        : switch (u.risk) {
            Risk.low => WarningLayer.none,
            Risk.medium => WarningLayer.caution,
            Risk.high => WarningLayer.warning,
          };
    final content = WarningContent.from(u);

    if (layer == WarningLayer.warning) {
      if (before.layer != WarningLayer.warning ||
          content.command != before.content.command) {
        _buzzer.startWarningPattern();
      }
    } else if (before.layer == WarningLayer.warning) {
      _buzzer.stop();
    }
    _set(_state.copyWith(layer: layer, content: content));
  }

  void _set(WarningState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _repository.connected.removeListener(_onConnection);
    _buzzer.stop();
    super.dispose();
  }
}
