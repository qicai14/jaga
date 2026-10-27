import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/models/family_alert.dart';
import '../../../data/models/linked_person.dart';
import '../../../data/models/stage.dart';
import '../../../data/repositories/family_alert_repository.dart';
import '../../../data/services/dialer_service.dart';

/// What the family alert screen shows.
@immutable
class FamilyAlertState {
  const FamilyAlertState({
    required this.kind,
    required this.personName,
    required this.stage,
    required this.summary,
    required this.quotes,
    required this.at,
    required this.canDial,
    this.agency,
  });

  final FamilyAlertKind kind;
  final String personName;
  final Stage stage;
  final String summary;
  final List<String> quotes;
  final DateTime at;
  final String? agency;

  /// A number is known. False: the Call button opens the dialer empty.
  final bool canDial;
}

/// One call's alert, updated in place by later pushes for the same call.
class FamilyAlertViewModel extends ChangeNotifier {
  FamilyAlertViewModel({
    required FamilyAlertRepository repository,
    required this._dialer,
    required FamilyAlert initial,
  }) : _person = repository.person,
       _callId = initial.callId {
    _state = _stateOf(repository.receive(initial));
    _sub = repository.alerts
        .where((a) => a.callId == _callId)
        .listen((a) => _set(_stateOf(a)));
  }

  final LinkedPerson _person;
  final DialerService _dialer;
  final String _callId;
  late final StreamSubscription<FamilyAlert> _sub;

  late FamilyAlertState _state;
  FamilyAlertState get state => _state;

  Future<void> call() => _dialer.dial(_person.phoneNumber);

  /// The nickname on this phone wins over the name in the push; the quotes of a
  /// "may be genuine" follow-up are hidden.
  FamilyAlertState _stateOf(FamilyAlert a) => FamilyAlertState(
    kind: a.kind,
    personName: _person.name,
    stage: a.stage,
    summary: a.summary,
    quotes: a.kind == FamilyAlertKind.alert ? a.quotes : const [],
    at: a.at,
    agency: a.claimedAgency,
    canDial: _person.phoneNumber != null,
  );

  void _set(FamilyAlertState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
