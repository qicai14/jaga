import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/services/device_setup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('twilio_voice/messages');
  late List<String> calls;

  void stub({required bool enabled}) {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return call.method == 'isPhoneAccountEnabled' ? enabled : true;
        });
  }

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'calling account Fix opens the page when registering leaves it off',
    () async {
      stub(enabled: false);
      await const AndroidDeviceSetupService().fix(SetupItem.callingAccount);
      expect(calls, [
        'registerPhoneAccount',
        'isPhoneAccountEnabled',
        'openPhoneAccountSettings',
      ]);
    },
  );

  test('calling account Fix opens nothing when it is already on', () async {
    stub(enabled: true);
    await const AndroidDeviceSetupService().fix(SetupItem.callingAccount);
    expect(calls, ['registerPhoneAccount', 'isPhoneAccountEnabled']);
  });
}
