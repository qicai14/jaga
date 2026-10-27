import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/l10n/stage_labels.dart';
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

  void dispose();
}

const alertChannelId = 'family_alerts';
const updateChannelId = 'family_updates';
const callActionId = 'call';

/// Stable across runs, so a push after a restart still replaces the earlier one.
int notificationIdFor(String callId) =>
    callId.codeUnits.fold(0, (h, c) => (h * 31 + c) & 0x7fffffff);

/// What one notification says and how loudly. The lock screen shows the stage
/// and agency, never quotes or the summary.
@immutable
class AlertContent {
  const AlertContent({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    required this.channelId,
    required this.channelName,
    required this.importance,
  });

  final int id;
  final String title;
  final String body;

  /// The alert as JSON, handed back when the notification is tapped.
  final String payload;
  final String channelId;
  final String channelName;
  final Importance importance;
}

/// The "may be genuine" follow-up arrives quietly; everything else heads-up.
AlertContent alertContentFor(
  FamilyAlert alert,
  LinkedPerson person,
  AppLocalizations l,
) {
  final genuine = alert.kind == FamilyAlertKind.mayBeGenuine;
  final stage = alert.stage.label(l);
  final agency = alert.claimedAgency;
  return AlertContent(
    id: notificationIdFor(alert.callId),
    title: genuine
        ? l.familyNotifGenuineTitle(person.name)
        : l.familyNotifTitle(person.name),
    body: genuine
        ? l.familyGenuineBody(person.name)
        : agency == null
        ? l.familyNotifBody(stage)
        : l.familyNotifBodyAgency(stage, agency),
    payload: jsonEncode(alert.toJson()),
    channelId: genuine ? updateChannelId : alertChannelId,
    channelName: genuine
        ? l.familyNotifChannelUpdates
        : l.familyNotifChannelAlerts,
    importance: genuine ? Importance.low : Importance.max,
  );
}

/// A tap on a notification, or null when it carries no readable alert.
AlertOpen? alertOpenFrom(NotificationResponse r) {
  final payload = r.payload;
  if (payload == null) return null;
  try {
    return AlertOpen(
      FamilyAlert.parse(payload),
      autoDial: r.actionId == callActionId,
    );
  } catch (e) {
    debugPrint('Ignoring a notification with a bad payload: $e');
    return null;
  }
}

/// Local notifications, in the app's language at the moment they are shown.
class LocalAlertNotifier implements AlertNotifier {
  LocalAlertNotifier({
    required this._locale,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final Locale Function() _locale;
  final FlutterLocalNotificationsPlugin _plugin;
  final _opens = StreamController<AlertOpen>.broadcast();

  AppLocalizations get _l => lookupAppLocalizations(_locale());

  @override
  Stream<AlertOpen> get opens => _opens.stream;

  /// Creates the channels and, unless [askPermission] is false (a background
  /// isolate has no activity to ask from), the notification permission.
  Future<void> init({bool askPermission = true}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_jaga'),
      ),
      onDidReceiveNotificationResponse: (r) {
        final open = alertOpenFrom(r);
        if (open != null) _opens.add(open);
      },
    );
    final l = _l;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!;
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        alertChannelId,
        l.familyNotifChannelAlerts,
        importance: Importance.max,
      ),
    );
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        updateChannelId,
        l.familyNotifChannelUpdates,
        importance: Importance.low,
      ),
    );
    if (askPermission) await android.requestNotificationsPermission();
  }

  @override
  Future<AlertOpen?> launchOpen() async {
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    return launch?.didNotificationLaunchApp == true && response != null
        ? alertOpenFrom(response)
        : null;
  }

  @override
  Future<void> show(FamilyAlert alert, LinkedPerson person) {
    final l = _l;
    final c = alertContentFor(alert, person, l);
    final loud = c.importance == Importance.max;
    return _plugin.show(
      id: c.id,
      title: c.title,
      body: c.body,
      payload: c.payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          c.channelId,
          c.channelName,
          importance: c.importance,
          priority: loud ? Priority.high : Priority.low,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.message,
          actions: [
            AndroidNotificationAction(
              callActionId,
              l.familyNotifCallAction(person.name),
              showsUserInterface: true,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() => _opens.close();
}

/// Records notifications for tests and the debug gallery.
class FakeAlertNotifier implements AlertNotifier {
  FakeAlertNotifier({this.launch, this.showError});

  final AlertOpen? launch;

  /// Thrown by every [show], to test failures.
  final Object? showError;
  final shown = <(FamilyAlert, LinkedPerson)>[];
  final _opens = StreamController<AlertOpen>.broadcast(sync: true);

  @override
  Stream<AlertOpen> get opens => _opens.stream;

  @override
  Future<AlertOpen?> launchOpen() async => launch;

  @override
  Future<void> show(FamilyAlert alert, LinkedPerson person) async {
    final error = showError;
    if (error != null) throw error;
    shown.add((alert, person));
  }

  void emitOpen(AlertOpen open) => _opens.add(open);

  @override
  void dispose() => _opens.close();
}
