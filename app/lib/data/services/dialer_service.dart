import 'package:url_launcher/url_launcher.dart';

abstract class DialerService {
  /// Opens the phone app, prefilled with [number] when known. The person
  /// presses call (no CALL_PHONE permission). False if no dialer opened.
  Future<bool> dial(String? number);
}

class UrlDialerService implements DialerService {
  const UrlDialerService();

  @override
  Future<bool> dial(String? number) async {
    try {
      return await launchUrl(Uri(scheme: 'tel', path: number ?? ''));
    } on Exception {
      return false;
    }
  }
}

/// Records numbers for tests and the debug gallery.
class FakeDialerService implements DialerService {
  /// What [dial] reports; set false to test a phone app that will not open.
  bool opens = true;
  final dialed = <String?>[];

  @override
  Future<bool> dial(String? number) async {
    dialed.add(number);
    return opens;
  }
}
