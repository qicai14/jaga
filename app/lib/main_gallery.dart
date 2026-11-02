// Debug gallery: `fvm flutter run -t lib/main_gallery.dart`. main.dart never imports lib/debug/.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/font_license.dart';
import 'debug/gallery_app.dart';
import 'debug/gallery_registry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicense();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(GalleryApp(entries: galleryEntries()));
}
