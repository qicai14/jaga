import 'package:flutter/services.dart';
import 'package:proximity_sensor/proximity_sensor.dart';

/// What the in-call screen asks of the phone's window (call.md section 3).
abstract class CallUiService {
  /// Screen off at the ear. Held only while the speaker is off and the screen is ours.
  Future<void> setProximityLock(bool on);

  /// Show over the lock screen and wake the screen while a call is on.
  Future<void> setShowWhenLocked(bool on);

  /// Sends Jaga to the background; the call goes on.
  Future<void> moveToBack();
}

class AndroidCallUiService implements CallUiService {
  const AndroidCallUiService();

  static const _channel = MethodChannel('jaga/call_ui');

  @override
  Future<void> setProximityLock(bool on) =>
      ProximitySensor.setProximityScreenOff(on);

  @override
  Future<void> setShowWhenLocked(bool on) =>
      _channel.invokeMethod<void>('setShowWhenLocked', on);

  @override
  Future<void> moveToBack() => _channel.invokeMethod<void>('moveToBack');
}

class FakeCallUiService implements CallUiService {
  bool proximityLock = false;
  bool showWhenLocked = false;
  int movedToBack = 0;

  @override
  Future<void> setProximityLock(bool on) async => proximityLock = on;

  @override
  Future<void> setShowWhenLocked(bool on) async => showWhenLocked = on;

  @override
  Future<void> moveToBack() async => movedToBack++;
}
