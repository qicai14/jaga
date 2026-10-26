import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/l10n/gen/app_localizations.dart';
import 'core/theme/font_license.dart';
import 'core/theme/jaga_theme.dart';

/// Until onboarding stores one (#10), the protected phone speaks Malay.
const _defaultLocale = Locale('ms');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicense();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const JagaApp());
}

class JagaApp extends StatelessWidget {
  const JagaApp({super.key, this.locale = _defaultLocale});

  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildJagaTheme(locale),
      themeMode: ThemeMode.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Center(
              child: Text(AppLocalizations.of(context).appTitle,
                  style: Theme.of(context).textTheme.displaySmall),
            ),
          ),
        ),
      ),
    );
  }
}
