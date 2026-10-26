import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lists the bundled Noto fonts (SIL OFL 1.1) in the app's licence page.
void registerFontLicense() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(
        ['Noto Sans, Noto Sans SC, Noto Sans Tamil'], text);
  });
}
