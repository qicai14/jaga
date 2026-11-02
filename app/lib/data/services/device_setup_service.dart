import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twilio_voice/twilio_voice.dart';

/// What the phone must allow for Jaga to work (onboarding.md section 5).
enum SetupItem {
  phoneCalls,
  notifications,
  microphone,
  fullScreenAlerts,
  displayOverApps,
  callingAccount,
  autostart,
}

/// The items Android can report, in the order step 4 lists them. A protected
/// phone needs them all; Xiaomi autostart can't be read.
const platformItems = [
  SetupItem.phoneCalls,
  SetupItem.microphone,
  SetupItem.callingAccount,
  SetupItem.displayOverApps,
  SetupItem.notifications,
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

class AndroidDeviceSetupService implements DeviceSetupService {
  const AndroidDeviceSetupService();

  static const _channel = MethodChannel('jaga/device_setup');

  /// Asked of the platform, so it can't drift from the build's `applicationId`.
  Future<String> _package() async =>
      (await _channel.invokeMethod<String>('packageName'))!;

  static TwilioVoicePlatform get _voice => TwilioVoicePlatform.instance;

  @override
  Future<Map<SetupItem, bool>> check() async => {
    SetupItem.phoneCalls:
        await _voice.hasReadPhoneStatePermission() &&
        await _voice.hasReadPhoneNumbersPermission() &&
        await _voice.hasCallPhonePermission(),
    SetupItem.notifications: await Permission.notification.isGranted,
    SetupItem.microphone: await Permission.microphone.isGranted,
    SetupItem.fullScreenAlerts:
        // Below Android 14 the platform side reports true.
        await _channel.invokeMethod<bool>('canUseFullScreenIntent') == true,
    SetupItem.displayOverApps: await Permission.systemAlertWindow.isGranted,
    SetupItem.callingAccount: await _voice.isPhoneAccountEnabled(),
    SetupItem.autostart: false,
  };

  @override
  Future<void> fix(SetupItem item) async {
    switch (item) {
      case SetupItem.phoneCalls:
        final granted =
            await _voice.requestReadPhoneStatePermission() == true &&
            await _voice.requestReadPhoneNumbersPermission() == true &&
            await _voice.requestCallPhonePermission() == true;
        if (!granted) await openAppSettings();
      case SetupItem.notifications:
        final status = await Permission.notification.request();
        if (status.isPermanentlyDenied) {
          await _open(
            AndroidIntent(
              action: 'android.settings.APP_NOTIFICATION_SETTINGS',
              arguments: {
                'android.provider.extra.APP_PACKAGE': await _package(),
              },
            ),
          );
        }
      case SetupItem.microphone:
        if (!(await Permission.microphone.request()).isGranted) {
          await openAppSettings();
        }
      case SetupItem.fullScreenAlerts:
        await _open(
          AndroidIntent(
            action: 'android.settings.MANAGE_APP_USE_FULL_SCREEN_INTENT',
            data: 'package:${await _package()}',
          ),
        );
      case SetupItem.displayOverApps:
        // Opens the "Display over other apps" page for Jaga.
        await Permission.systemAlertWindow.request();
      case SetupItem.autostart:
        await _open(
          const AndroidIntent(
            package: 'com.miui.securitycenter',
            componentName:
                'com.miui.permcenter.autostart.AutoStartManagementActivity',
          ),
        );
      case SetupItem.callingAccount:
        try {
          await _voice.registerPhoneAccount();
          // Registering leaves the account switched off on Android: the user flips it in Settings.
          if (await _voice.isPhoneAccountEnabled()) return;
        } on PlatformException {
          // Fall through to the settings page.
        }
        // Samsung hides the calling-accounts page: try the settings page, then the app's own.
        try {
          await _voice.openPhoneAccountSettings();
        } on PlatformException {
          await openAppSettings();
        }
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
    final maker = (await DeviceInfoPlugin().androidInfo).manufacturer
        .toLowerCase();
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
