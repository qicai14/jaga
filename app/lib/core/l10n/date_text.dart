import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// A moment in the app language and the phone's time zone.
extension DateText on DateTime {
  String formatDay(BuildContext context) =>
      DateFormat.yMMMd(_locale(context)).format(toLocal());

  String formatTime(BuildContext context) =>
      DateFormat.jm(_locale(context)).format(toLocal());

  String formatDayAndTime(BuildContext context) =>
      DateFormat.yMMMd(_locale(context)).add_jm().format(toLocal());

  static String _locale(BuildContext context) =>
      Localizations.localeOf(context).toString();
}
