import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms'),
    Locale('ta'),
    Locale('zh'),
  ];

  /// App name. Window title and the placeholder home screen.
  ///
  /// In en, this message translates to:
  /// **'Jaga'**
  String get appTitle;

  /// Status hero on the protected user's home screen, and the 'protected' badge.
  ///
  /// In en, this message translates to:
  /// **'Jaga is protecting you'**
  String get statusProtected;

  /// Badge shown while Jaga Pause is on.
  ///
  /// In en, this message translates to:
  /// **'Jaga Pause active'**
  String get statusPauseActive;

  /// Semantics label only, never shown as text. The reconnecting dot on the call and Warning screens.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get callReconnecting;

  /// TalkBack hint on every hold-to-confirm button.
  ///
  /// In en, this message translates to:
  /// **'Hold for 2 seconds'**
  String get commonHoldHint;

  /// Announced when a hold-to-confirm button is armed in TalkBack two-tap mode.
  ///
  /// In en, this message translates to:
  /// **'Tap again to confirm'**
  String get commonTapAgainHint;

  /// Stage bar label, step 1: the caller opened with a pretext.
  ///
  /// In en, this message translates to:
  /// **'Gave a reason to call'**
  String get stageLabelPretext;

  /// Stage bar label, step 2.
  ///
  /// In en, this message translates to:
  /// **'Claimed to be an official'**
  String get stageLabelAuthority;

  /// Stage bar label, step 3.
  ///
  /// In en, this message translates to:
  /// **'Made you afraid'**
  String get stageLabelFear;

  /// Stage bar label, step 4.
  ///
  /// In en, this message translates to:
  /// **'Told to keep it secret'**
  String get stageLabelIsolation;

  /// Stage bar label, step 5.
  ///
  /// In en, this message translates to:
  /// **'Passed to another person'**
  String get stageLabelHandoff;

  /// Stage bar label, step 6.
  ///
  /// In en, this message translates to:
  /// **'Asked to move money'**
  String get stageLabelMoney;

  /// Stage bar label, step 6 (ties with money).
  ///
  /// In en, this message translates to:
  /// **'Asked for codes or passwords'**
  String get stageLabelCredentials;

  /// TalkBack label of the stage progress bar.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}: {label}'**
  String stageStepSemantics(int step, int total, String label);

  /// Caution banner text (medium risk), glossary wording.
  ///
  /// In en, this message translates to:
  /// **'This call has signs of a scam'**
  String get cautionBannerText;

  /// Visible label in the Warning masthead, next to the Jaga wordmark.
  ///
  /// In en, this message translates to:
  /// **'Scam warning'**
  String get warningSemanticsLabel;

  /// Route name of the full-screen Warning, read by TalkBack once. Jaga is never translated.
  ///
  /// In en, this message translates to:
  /// **'Scam warning from Jaga'**
  String get warningFromJaga;

  /// Label above the masked quote on the Warning.
  ///
  /// In en, this message translates to:
  /// **'The caller said'**
  String get warningEvidenceLabel;

  /// The big hang-up button on the Warning. She presses it; Jaga never hangs up itself.
  ///
  /// In en, this message translates to:
  /// **'Hang up'**
  String get warningHangUp;

  /// Hold-to-dismiss button on the Caution banner and the Warning.
  ///
  /// In en, this message translates to:
  /// **'This call is fine'**
  String get warningDismissLabel;

  /// TalkBack hint on the dismiss button.
  ///
  /// In en, this message translates to:
  /// **'Hold for 2 seconds'**
  String get warningDismissHint;

  /// Announced when the dismiss button is armed in TalkBack two-tap mode.
  ///
  /// In en, this message translates to:
  /// **'Tap again to confirm this call is fine'**
  String get warningDismissConfirmHint;

  /// Safety-net command, same in every language. Only when the server sends no command at high risk. Wording to be approved by Lane D (Q35).
  ///
  /// In en, this message translates to:
  /// **'Letak telefon. Hang up.'**
  String get warningCommandFallback;

  /// Android notification channel name for urgent family alerts.
  ///
  /// In en, this message translates to:
  /// **'Scam alerts'**
  String get familyNotifChannelAlerts;

  /// Android notification channel name for quiet follow-ups ('may be genuine').
  ///
  /// In en, this message translates to:
  /// **'Call updates'**
  String get familyNotifChannelUpdates;

  /// Notification title (lock screen). name is the protected user's name.
  ///
  /// In en, this message translates to:
  /// **'{name} may be on a scam call'**
  String familyNotifTitle(String name);

  /// Notification body without an agency. stage is the plain-word stage label. Never quotes or summary.
  ///
  /// In en, this message translates to:
  /// **'{stage}.'**
  String familyNotifBody(String stage);

  /// Notification body with an agency. stage is the stage label, agency the one the caller claimed.
  ///
  /// In en, this message translates to:
  /// **'{stage}. Says they are from {agency}.'**
  String familyNotifBodyAgency(String stage, String agency);

  /// Notification title of the 'may be genuine' follow-up.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s call may be genuine'**
  String familyNotifGenuineTitle(String name);

  /// Notification action button that calls the protected user.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String familyNotifCallAction(String name);

  /// Family alert headline in the amber band.
  ///
  /// In en, this message translates to:
  /// **'{name} may be on a scam call'**
  String familyAlertHeadline(String name);

  /// Time line under the family alert headline. time is already formatted.
  ///
  /// In en, this message translates to:
  /// **'Alert at {time}'**
  String familyAlertTime(String time);

  /// Label above the agency the caller claimed, on the family alert.
  ///
  /// In en, this message translates to:
  /// **'The caller says they are from'**
  String get familyAlertAgencyLabel;

  /// Label above the masked quotes on the family alert.
  ///
  /// In en, this message translates to:
  /// **'The caller said'**
  String get familyAlertQuotesLabel;

  /// The family alert's one button. name is the protected user.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String familyAlertCall(String name);

  /// Button label when no number is known for the protected user.
  ///
  /// In en, this message translates to:
  /// **'Open the phone app'**
  String get familyAlertOpenDialer;

  /// Headline of the 'may be genuine' follow-up (blue band).
  ///
  /// In en, this message translates to:
  /// **'{name}\'s call may be genuine'**
  String familyGenuineHeadline(String name);

  /// Calm text of the follow-up. Also the follow-up notification body.
  ///
  /// In en, this message translates to:
  /// **'Jaga now thinks this call is less likely to be a scam. You can still call {name} to check.'**
  String familyGenuineBody(String name);

  /// The family alert button when the protected user's name is long: the name stays in the TalkBack label.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get familyAlertCallShort;

  /// Shown above the Call button when the phone app would not open. The number, if known, is shown under it so the co-pilot can dial it themselves.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the phone app.'**
  String get familyAlertDialFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ms', 'ta', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
    case 'ta':
      return AppLocalizationsTa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
