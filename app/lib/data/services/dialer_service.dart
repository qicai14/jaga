import 'package:url_launcher/url_launcher.dart';

abstract class DialerService {
  /// Opens the phone app, prefilled with [number] when known. The person
  /// presses call (no CALL_PHONE permission). False if no dialer opened.
  Future<bool> dial(String? number);
}

class UrlDialerService implements DialerService {
  const UrlDialerService();

  @override
  Future<bool> dial(String? number) =>
      launchUrl(Uri(scheme: 'tel', path: number ?? ''));
}

/// Records numbers for tests and the debug gallery.
class FakeDialerService implements DialerService {
  final dialed = <String?>[];

  @override
  Future<bool> dial(String? number) async {
    dialed.add(number);
    return true;
  }
}
