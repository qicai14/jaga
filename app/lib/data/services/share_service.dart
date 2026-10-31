import 'package:share_plus/share_plus.dart';

abstract class ShareService {
  Future<void> share(String text);
}

class SharePlusService implements ShareService {
  const SharePlusService();

  @override
  Future<void> share(String text) =>
      SharePlus.instance.share(ShareParams(text: text));
}

/// Records what would be shared, for tests and the debug gallery.
class FakeShareService implements ShareService {
  final shared = <String>[];

  @override
  Future<void> share(String text) async => shared.add(text);
}
