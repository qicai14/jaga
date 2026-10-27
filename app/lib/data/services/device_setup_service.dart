import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// What the phone must allow for Jaga to work (onboarding.md section 5).
enum SetupItem { notifications, microphone, fullScreenAlerts, callingAccount, autostart }

/// The items Android can report. A protected phone needs them all; the calling
/// account waits for #12 and Xiaomi autostart can't be read.
const platformItems = [
  SetupItem.notifications,
  SetupItem.microphone,
  SetupItem.fullScreenAlerts,
];

bool platformItemsOk(Map<SetupItem, bool> state) =>
    platformItems.every((i) => state[i] == true);

abstract class DeviceSetupService {
  /// The current state of every readable item. Never cached: call it again on resume.
  Future<Map<SetupItem, bool>> check();

  /// Asks for [item], or opens the Android settings page where it is switched on.
  Future<void> fix(SetupItem item);

  /// Xiaomi, Redmi and POCO kill background apps unless autostart is on.
  Future<bool> isXiaomi();
}

/// Must match `applicationId` in android/app/build.gradle.kts.
const _appPackage = 'my.jaga.jaga';
const _fullScreenIntentSdk = 34;

class AndroidDeviceSetupService implements DeviceSetupService {
  const AndroidDeviceSetupService();

  static const _channel = MethodChannel('jaga/device_setup');

  Future<int> _sdk() async => (await DeviceInfoPlugin().androidInfo).version.sdkInt;

  @override
  Future<Map<SetupItem, bool>> check() async => {
    SetupItem.notifications: await Permission.notification.isGranted,
    SetupItem.microphone: await Permission.microphone.isGranted,
    SetupItem.fullScreenAlerts:
        await _sdk() < _fullScreenIntentSdk ||
        await _channel.invokeMethod<bool>('canUseFullScreenIntent') == true,
    // Waits for #12 (twilio_voice); counted as done until then.
    SetupItem.callingAccount: false,
    SetupItem.autostart: false,
  };

  @override
  Future<void> fix(SetupItem item) async {
    switch (item) {
      case SetupItem.notifications:
        final status = await Permission.notification.request();
        if (status.isPermanentlyDenied) {
          await _open(
            const AndroidIntent(
              action: 'android.settings.APP_NOTIFICATION_SETTINGS',
              arguments: {'android.provider.extra.APP_PACKAGE': _appPackage},
            ),
          );
        }
      case SetupItem.microphone:
        if (!(await Permission.microphone.request()).isGranted) {
          await openAppSettings();
        }
      case SetupItem.fullScreenAlerts:
        await _open(
          const AndroidIntent(
            action: 'android.settings.MANAGE_APP_USE_FULL_SCREEN_INTENT',
            data: 'package:$_appPackage',
          ),
        );
      case SetupItem.autostart:
        await _open(
          const AndroidIntent(
            package: 'com.miui.securitycenter',
            componentName:
                'com.miui.permcenter.autostart.AutoStartManagementActivity',
          ),
        );
      case SetupItem.callingAccount:
        break; // Waits for #12.
    }
  }

  /// Some OEMs hide or rename the page: fall back to the app's own settings.
  Future<void> _open(AndroidIntent intent) async {
    try {
      await intent.launch();
    } on PlatformException {
      await openAppSettings();
    }
  }

  @override
  Future<bool> isXiaomi() async {
    final maker = (await DeviceInfoPlugin().androidInfo).manufacturer.toLowerCase();
    return const ['xiaomi', 'redmi', 'poco'].contains(maker);
  }
}

/// Settable state for tests and the debug gallery. [fix] turns the item green.
class FakeDeviceSetupService implements DeviceSetupService {
  FakeDeviceSetupService({
    Map<SetupItem, bool> state = const {},
    this.xiaomi = false,
  }) : state = {for (final i in SetupItem.values) i: state[i] ?? false};

  final Map<SetupItem, bool> state;
  bool xiaomi;
  final fixed = <SetupItem>[];

  @override
  Future<Map<SetupItem, bool>> check() async => {...state};

  @override
  Future<void> fix(SetupItem item) async {
    fixed.add(item);
    state[item] = true;
  }

  @override
  Future<bool> isXiaomi() async => xiaomi;
}
