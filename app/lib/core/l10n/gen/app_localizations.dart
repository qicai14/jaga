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

  /// Label above the official number on the Warning. agency is the agency the caller claimed.
  ///
  /// In en, this message translates to:
  /// **'{agency}\'s official number'**
  String warningOfficialNumberLabel(String agency);

  /// Label above the official number when no agency was claimed.
  ///
  /// In en, this message translates to:
  /// **'Official number'**
  String get warningOfficialNumberLabelNoAgency;

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

  /// Copy button next to a token or code.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// SnackBar after Copy.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get commonCopied;

  /// Share button next to a token or code.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// Cancel button, e.g. on the co-pilot lock sheet.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Debug builds only: skips the call forwarding step.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// Semantics label only: the PIN pad's delete-a-digit key.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Semantics label only: how many PIN digits are typed.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} digits entered'**
  String commonPinEntered(int count, int total);

  /// Setup app bar title.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardingStepOf(int step, int total);

  /// Primary button on every setup step.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// Setup step 2 title, both roles.
  ///
  /// In en, this message translates to:
  /// **'Who is this phone for?'**
  String get onboardingRoleTitle;

  /// Step 2 choice: the protected user.
  ///
  /// In en, this message translates to:
  /// **'The person Jaga protects'**
  String get onboardingRoleProtected;

  /// Step 2 choice body.
  ///
  /// In en, this message translates to:
  /// **'Calls to this phone will ring in Jaga.'**
  String get onboardingRoleProtectedBody;

  /// Step 2 choice: the family co-pilot. Also quoted in the link code share text.
  ///
  /// In en, this message translates to:
  /// **'A family co-pilot'**
  String get onboardingRoleCopilot;

  /// Step 2 choice body.
  ///
  /// In en, this message translates to:
  /// **'Get alerts about someone you look after.'**
  String get onboardingRoleCopilotBody;

  /// Protected user settings: title of the command language list.
  ///
  /// In en, this message translates to:
  /// **'Which language should warnings use?'**
  String get onboardingLanguageTitle;

  /// Setup step 1 title, both roles: the app language, which on a protected phone is also the command language.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboardingAppLanguageTitle;

  /// Protected setup step 3 title.
  ///
  /// In en, this message translates to:
  /// **'About her'**
  String get onboardingAboutTitle;

  /// Step 3 name field label.
  ///
  /// In en, this message translates to:
  /// **'Her name'**
  String get onboardingNameLabel;

  /// Helper text under the field whose short label is Her name.
  ///
  /// In en, this message translates to:
  /// **'What does the family call her?'**
  String get onboardingNameHelper;

  /// Step 3 read-only region row.
  ///
  /// In en, this message translates to:
  /// **'Region: Malaysia. Jaga uses Malaysia\'s official numbers.'**
  String get onboardingRegionInfo;

  /// Step 3 button while registering.
  ///
  /// In en, this message translates to:
  /// **'Setting up…'**
  String get onboardingSettingUp;

  /// Inline error when the server can't be reached.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach Jaga. Check the internet and try again.'**
  String get onboardingNetworkError;

  /// Protected setup step 4 title.
  ///
  /// In en, this message translates to:
  /// **'Phone permissions'**
  String get onboardingPermissionsTitle;

  /// Button on a permission row that is not granted yet.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get onboardingFix;

  /// Manual tick for a permission Android can't report.
  ///
  /// In en, this message translates to:
  /// **'I\'ve done this'**
  String get onboardingFixedIt;

  /// Permission row title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get onboardingPermNotifications;

  /// Permission row reason.
  ///
  /// In en, this message translates to:
  /// **'Shows alerts.'**
  String get onboardingPermNotificationsWhy;

  /// Permission row title.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get onboardingPermMicrophone;

  /// Permission row reason.
  ///
  /// In en, this message translates to:
  /// **'Lets you talk on calls through Jaga.'**
  String get onboardingPermMicrophoneWhy;

  /// Permission row title.
  ///
  /// In en, this message translates to:
  /// **'Full-screen alerts'**
  String get onboardingPermFullScreen;

  /// Permission row reason.
  ///
  /// In en, this message translates to:
  /// **'Lets the warning fill the screen.'**
  String get onboardingPermFullScreenWhy;

  /// Permission row title.
  ///
  /// In en, this message translates to:
  /// **'Calling account'**
  String get onboardingPermCallingAccount;

  /// Permission row reason.
  ///
  /// In en, this message translates to:
  /// **'Lets calls ring in Jaga.'**
  String get onboardingPermCallingAccountWhy;

  /// Permission row title, Xiaomi phones only.
  ///
  /// In en, this message translates to:
  /// **'Start automatically'**
  String get onboardingPermAutostart;

  /// Permission row reason.
  ///
  /// In en, this message translates to:
  /// **'Keeps Jaga running on Xiaomi phones.'**
  String get onboardingPermAutostartWhy;

  /// Calling account row, until calls are built.
  ///
  /// In en, this message translates to:
  /// **'Set up later with calls'**
  String get onboardingAfterCallSetup;

  /// Protected setup step 5 title.
  ///
  /// In en, this message translates to:
  /// **'Forward calls to Jaga'**
  String get onboardingForwardTitle;

  /// Step 5 body, above the code to dial.
  ///
  /// In en, this message translates to:
  /// **'Dial this code once. Calls to this phone will then ring in Jaga.'**
  String get onboardingForwardBody;

  /// Step 5 button: opens the dialer with the code.
  ///
  /// In en, this message translates to:
  /// **'Dial now'**
  String get onboardingDialNow;

  /// Step 5 secondary button: dials the forwarding check code.
  ///
  /// In en, this message translates to:
  /// **'Check forwarding'**
  String get onboardingCheckForwarding;

  /// Step 5 Continue label.
  ///
  /// In en, this message translates to:
  /// **'I\'ve dialled it'**
  String get onboardingForwardDone;

  /// Protected setup step 6 title: the co-pilot lock.
  ///
  /// In en, this message translates to:
  /// **'Set the co-pilot lock'**
  String get onboardingPinTitle;

  /// Step 6 body.
  ///
  /// In en, this message translates to:
  /// **'Only family can change Jaga\'s settings with this PIN, so a caller can\'t talk her into switching it off.'**
  String get onboardingPinBody;

  /// Step 6 prompt for the second entry.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN again'**
  String get onboardingPinConfirm;

  /// Step 6 error when the two entries differ.
  ///
  /// In en, this message translates to:
  /// **'The PINs don\'t match. Set it again.'**
  String get onboardingPinMismatch;

  /// Protected setup step 7 title.
  ///
  /// In en, this message translates to:
  /// **'Pause token'**
  String get onboardingPauseTitle;

  /// Step 7 body.
  ///
  /// In en, this message translates to:
  /// **'Give this code to her bank once. When she makes a transfer, the bank checks with Jaga and can hold it if she\'s on a scam call.'**
  String get onboardingPauseBody;

  /// Protected setup step 8 title.
  ///
  /// In en, this message translates to:
  /// **'Link code'**
  String get onboardingLinkTitle;

  /// Step 8 body.
  ///
  /// In en, this message translates to:
  /// **'Up to 3 family members can enter this code in their own Jaga app.'**
  String get onboardingLinkBody;

  /// Text shared with the link code. The quoted label matches onboardingRoleCopilot.
  ///
  /// In en, this message translates to:
  /// **'Open Jaga, choose \"A family co-pilot\" and enter {code} to get alerts about {name}.'**
  String onboardingLinkShareText(String code, String name);

  /// Step 8 heading above the list of co-pilots who joined.
  ///
  /// In en, this message translates to:
  /// **'Joined so far'**
  String get onboardingJoined;

  /// Step 8 when nobody has joined.
  ///
  /// In en, this message translates to:
  /// **'No one yet'**
  String get onboardingJoinedNone;

  /// Protected setup step 9 title.
  ///
  /// In en, this message translates to:
  /// **'Feel the buzz'**
  String get onboardingBuzzTitle;

  /// Step 9 body.
  ///
  /// In en, this message translates to:
  /// **'When the phone buzzes like this during a call, look at the screen.'**
  String get onboardingBuzzBody;

  /// Step 9 button: plays the Warning buzz once.
  ///
  /// In en, this message translates to:
  /// **'Feel the buzz'**
  String get onboardingBuzzButton;

  /// Protected setup step 10 headline.
  ///
  /// In en, this message translates to:
  /// **'Jaga is set up.'**
  String get onboardingDoneProtected;

  /// Last step button, both roles.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get onboardingFinish;

  /// Co-pilot setup step 3 title.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get onboardingJoinCode;

  /// Co-pilot step 3 title once the code is accepted.
  ///
  /// In en, this message translates to:
  /// **'A few details'**
  String get onboardingNamesTitle;

  /// Co-pilot name field: shown to the protected user.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get onboardingYourName;

  /// Co-pilot field: the nickname used in alerts, kept on this phone.
  ///
  /// In en, this message translates to:
  /// **'Her nickname'**
  String get onboardingCallHer;

  /// Helper text under the field whose short label is Her nickname.
  ///
  /// In en, this message translates to:
  /// **'What do you call her?'**
  String get onboardingCallHerHelper;

  /// Link code error.
  ///
  /// In en, this message translates to:
  /// **'That code doesn\'t match. Check the 6 digits.'**
  String get onboardingCodeWrong;

  /// Link code error.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Ask for a new one.'**
  String get onboardingCodeExpired;

  /// Link code error: three co-pilots already joined.
  ///
  /// In en, this message translates to:
  /// **'3 family co-pilots are already linked. One must unlink before you can join.'**
  String get onboardingCopilotsFull;

  /// Co-pilot setup step 4 title.
  ///
  /// In en, this message translates to:
  /// **'Allow alerts'**
  String get onboardingNotifTitle;

  /// Co-pilot step 4 body.
  ///
  /// In en, this message translates to:
  /// **'Jaga sends an alert here when someone you look after may be on a scam call.'**
  String get onboardingNotifBody;

  /// Co-pilot step 4: skip allowing notifications.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboardingNotNow;

  /// Co-pilot setup last step, and the placeholder home.
  ///
  /// In en, this message translates to:
  /// **'You\'ll get alerts about {name}.'**
  String onboardingDoneCopilot(String name);

  /// Status screen label above the co-pilots' names.
  ///
  /// In en, this message translates to:
  /// **'Your family'**
  String get statusFamilyLabel;

  /// Status screen when no co-pilot has joined.
  ///
  /// In en, this message translates to:
  /// **'No family linked yet'**
  String get statusFamilyNone;

  /// Status screen headline when a permission was switched off.
  ///
  /// In en, this message translates to:
  /// **'Ask your family to check Jaga'**
  String get statusNeedsFamily;

  /// Settings screen title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Sheet title when the status screen is long-pressed.
  ///
  /// In en, this message translates to:
  /// **'Enter the co-pilot lock'**
  String get settingsPinTitle;

  /// Co-pilot lock sheet: wrong PIN.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get settingsPinWrong;

  /// Co-pilot lock sheet after five wrong tries.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait 5 minutes.'**
  String get settingsPinLocked;

  /// Settings: hold-to-confirm button that resets Jaga.
  ///
  /// In en, this message translates to:
  /// **'Hold to reset Jaga'**
  String get settingsReset;
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
