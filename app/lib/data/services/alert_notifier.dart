import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/widgets/stage_progress_bar.dart';
import '../models/family_alert.dart';
import '../models/linked_person.dart';

/// The co-pilot opened a family alert from its notification.
class AlertOpen {
  const AlertOpen(this.alert, {this.autoDial = false});

  final FamilyAlert alert;

  /// The notification's Call action was pressed: dial straight away.
  final bool autoDial;
}

abstract class AlertNotifier {
  /// Notification taps while the app runs.
  Stream<AlertOpen> get opens;

  /// The tap that launched the app from a terminated state, if any.
  Future<AlertOpen?> launchOpen();

  Future<void> show(FamilyAlert alert, LinkedPerson person);
}

const alertChannelId = 'family_alerts';
const updateChannelId = 'family_updates';
const _callActionId = 'call';

/// Stable across runs, so a push after a restart still replaces the earlier one.
int notificationIdFor(String callId) =>
    callId.codeUnits.fold(0, (h, c) => (h * 31 + c) & 0x7fffffff);

/// The "may be genuine" follow-up arrives quietly; everything else heads-up.
String channelIdFor(FamilyAlertKind kind) =>
    kind == FamilyAlertKind.alert ? alertChannelId : updateChannelId;

/// Local notifications, in the app's language. The lock screen shows the stage
/// and agency, never quotes or the summary.
class LocalAlertNotifier implements AlertNotifier {
  LocalAlertNotifier({
    required Locale locale,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _l = lookupAppLocalizations(locale),
       _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final AppLocalizations _l;
  final FlutterLocalNotificationsPlugin _plugin;
  final _opens = StreamController<AlertOpen>.broadcast();

  @override
  Stream<AlertOpen> get opens => _opens.stream;

  /// Creates the channels and asks for the notification permission.
  Future<void> init() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) {
        final open = _parse(r);
        if (open != null) _opens.add(open);
      },
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!;
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        alertChannelId,
        _l.familyNotifChannelAlerts,
        importance: Importance.max,
      ),
    );
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        updateChannelId,
        _l.familyNotifChannelUpdates,
        importance: Importance.low,
      ),
    );
    await android.requestNotificationsPermission();
  }

  @override
  Future<AlertOpen?> launchOpen() async {
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    return launch?.didNotificationLaunchApp == true && response != null
        ? _parse(response)
        : null;
  }

  @override
  Future<void> show(FamilyAlert alert, LinkedPerson person) {
    final genuine = alert.kind == FamilyAlertKind.mayBeGenuine;
    final stage = alert.stage.label(_l);
    final agency = alert.claimedAgency;
    return _plugin.show(
      id: notificationIdFor(alert.callId),
      title: genuine
          ? _l.familyNotifGenuineTitle(person.name)
          : _l.familyNotifTitle(person.name),
      body: genuine
          ? _l.familyGenuineBody(person.name)
          : agency == null
          ? _l.familyNotifBody(stage)
          : _l.familyNotifBodyAgency(stage, agency),
      payload: jsonEncode(alert.toJson()),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelIdFor(alert.kind),
          genuine ? _l.familyNotifChannelUpdates : _l.familyNotifChannelAlerts,
          importance: genuine ? Importance.low : Importance.max,
          priority: genuine ? Priority.low : Priority.high,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.message,
          actions: [
            AndroidNotificationAction(
              _callActionId,
              _l.familyNotifCallAction(person.name),
              showsUserInterface: true,
            ),
          ],
        ),
      ),
    );
  }

  AlertOpen? _parse(NotificationResponse r) {
    final payload = r.payload;
    if (payload == null) return null;
    try {
      return AlertOpen(
        FamilyAlert.parse(payload),
        autoDial: r.actionId == _callActionId,
      );
    } catch (e) {
      debugPrint('Ignoring a notification with a bad payload: $e');
      return null;
    }
  }
}

/// Records notifications for tests and the debug gallery.
class FakeAlertNotifier implements AlertNotifier {
  FakeAlertNotifier({this.launch});

  final AlertOpen? launch;
  final shown = <(FamilyAlert, LinkedPerson)>[];
  final _opens = StreamController<AlertOpen>.broadcast(sync: true);

  @override
  Stream<AlertOpen> get opens => _opens.stream;

  @override
  Future<AlertOpen?> launchOpen() async => launch;

  @override
  Future<void> show(FamilyAlert alert, LinkedPerson person) async =>
      shown.add((alert, person));

  void emitOpen(AlertOpen open) => _opens.add(open);

  void dispose() => _opens.close();
}
