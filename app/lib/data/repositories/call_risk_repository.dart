import 'package:flutter/foundation.dart';

import '../models/stage_update.dart';
import '../services/stage_stream_service.dart';

/// The call's risk stream, minus updates for any other call.
class CallRiskRepository {
  CallRiskRepository(this._service, {this.callId});

  final StageStreamService _service;

  /// The call this phone is on. Null accepts any (the view model then resets
  /// when the id changes).
  final String? callId;

  Stream<StageUpdate> get updates =>
      _service.updates.where((u) => callId == null || u.callId == callId);

  ValueListenable<bool> get connected => _service.connected;
}
