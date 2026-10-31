import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'core/theme/font_license.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicense();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(JagaApp(deps: await createDependencies()));
}
