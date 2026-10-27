// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Jaga';

  @override
  String get statusProtected => 'Jaga is protecting you';

  @override
  String get statusPauseActive => 'Jaga Pause active';

  @override
  String get callReconnecting => 'Reconnecting';

  @override
  String get commonHoldHint => 'Hold for 2 seconds';

  @override
  String get commonTapAgainHint => 'Tap again to confirm';

  @override
  String get stageLabelPretext => 'Gave a reason to call';

  @override
  String get stageLabelAuthority => 'Claimed to be an official';

  @override
  String get stageLabelFear => 'Made you afraid';

  @override
  String get stageLabelIsolation => 'Told to keep it secret';

  @override
  String get stageLabelHandoff => 'Passed to another person';

  @override
  String get stageLabelMoney => 'Asked to move money';

  @override
  String get stageLabelCredentials => 'Asked for codes or passwords';

  @override
  String stageStepSemantics(int step, int total, String label) {
    return 'Step $step of $total: $label';
  }

  @override
  String get cautionBannerText => 'This call has signs of a scam';

  @override
  String get warningSemanticsLabel => 'Scam warning';

  @override
  String get warningFromJaga => 'Scam warning from Jaga';

  @override
  String warningOfficialNumberLabel(String agency) {
    return '$agency\'s official number';
  }

  @override
  String get warningOfficialNumberLabelNoAgency => 'Official number';

  @override
  String get warningEvidenceLabel => 'The caller said';

  @override
  String get warningHangUp => 'Hang up';

  @override
  String get warningDismissLabel => 'This call is fine';

  @override
  String get warningDismissHint => 'Hold for 2 seconds';

  @override
  String get warningDismissConfirmHint =>
      'Tap again to confirm this call is fine';

  @override
  String get warningCommandFallback => 'Letak telefon. Hang up.';

  @override
  String get familyNotifChannelAlerts => 'Scam alerts';

  @override
  String get familyNotifChannelUpdates => 'Call updates';

  @override
  String familyNotifTitle(String name) {
    return '$name may be on a scam call';
  }

  @override
  String familyNotifBody(String stage) {
    return '$stage.';
  }

  @override
  String familyNotifBodyAgency(String stage, String agency) {
    return '$stage. Says they are from $agency.';
  }

  @override
  String familyNotifGenuineTitle(String name) {
    return '$name\'s call may be genuine';
  }

  @override
  String familyNotifCallAction(String name) {
    return 'Call $name';
  }

  @override
  String familyAlertHeadline(String name) {
    return '$name may be on a scam call';
  }

  @override
  String familyAlertTime(String time) {
    return 'Alert at $time';
  }

  @override
  String get familyAlertAgencyLabel => 'The caller says they are from';

  @override
  String get familyAlertQuotesLabel => 'The caller said';

  @override
  String familyAlertCall(String name) {
    return 'Call $name';
  }

  @override
  String get familyAlertOpenDialer => 'Open the phone app';

  @override
  String familyGenuineHeadline(String name) {
    return '$name\'s call may be genuine';
  }

  @override
  String familyGenuineBody(String name) {
    return 'Jaga now thinks this call is less likely to be a scam. You can still call $name to check.';
  }

  @override
  String get familyAlertCallShort => 'Call';

  @override
  String get familyAlertDialFailed => 'Couldn\'t open the phone app.';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied';

  @override
  String get commonShare => 'Share';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonDelete => 'Delete';

  @override
  String commonPinEntered(int count, int total) {
    return '$count of $total digits entered';
  }

  @override
  String onboardingStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingRoleTitle => 'Who is this phone for?';

  @override
  String get onboardingRoleProtected => 'The person Jaga protects';

  @override
  String get onboardingRoleProtectedBody =>
      'Calls to this phone will ring in Jaga.';

  @override
  String get onboardingRoleCopilot => 'A family co-pilot';

  @override
  String get onboardingRoleCopilotBody =>
      'Get alerts about someone you look after.';

  @override
  String get onboardingLanguageTitle => 'Which language should warnings use?';

  @override
  String get onboardingAppLanguageTitle => 'Choose your language';

  @override
  String get onboardingAboutTitle => 'About her';

  @override
  String get onboardingNameLabel => 'Her name';

  @override
  String get onboardingNameHelper => 'What does the family call her?';

  @override
  String get onboardingRegionInfo =>
      'Region: Malaysia. Jaga uses Malaysia\'s official numbers.';

  @override
  String get onboardingSettingUp => 'Setting up…';

  @override
  String get onboardingNetworkError =>
      'Can\'t reach Jaga. Check the internet and try again.';

  @override
  String get onboardingPermissionsTitle => 'Phone permissions';

  @override
  String get onboardingFix => 'Fix';

  @override
  String get onboardingFixedIt => 'I\'ve done this';

  @override
  String get onboardingPermNotifications => 'Notifications';

  @override
  String get onboardingPermNotificationsWhy => 'Shows alerts.';

  @override
  String get onboardingPermMicrophone => 'Microphone';

  @override
  String get onboardingPermMicrophoneWhy =>
      'Lets you talk on calls through Jaga.';

  @override
  String get onboardingPermFullScreen => 'Full-screen alerts';

  @override
  String get onboardingPermFullScreenWhy => 'Lets the warning fill the screen.';

  @override
  String get onboardingPermCallingAccount => 'Calling account';

  @override
  String get onboardingPermCallingAccountWhy => 'Lets calls ring in Jaga.';

  @override
  String get onboardingPermAutostart => 'Start automatically';

  @override
  String get onboardingPermAutostartWhy =>
      'Keeps Jaga running on Xiaomi phones.';

  @override
  String get onboardingAfterCallSetup => 'Set up later with calls';

  @override
  String get onboardingForwardTitle => 'Forward calls to Jaga';

  @override
  String get onboardingForwardBody =>
      'Dial this code once. Calls to this phone will then ring in Jaga.';

  @override
  String get onboardingDialNow => 'Dial now';

  @override
  String get onboardingCheckForwarding => 'Check forwarding';

  @override
  String get onboardingForwardDone => 'I\'ve dialled it';

  @override
  String get onboardingPinTitle => 'Set the co-pilot lock';

  @override
  String get onboardingPinBody =>
      'Only family can change Jaga\'s settings with this PIN, so a caller can\'t talk her into switching it off.';

  @override
  String get onboardingPinConfirm => 'Enter the PIN again';

  @override
  String get onboardingPinMismatch => 'The PINs don\'t match. Set it again.';

  @override
  String get onboardingPauseTitle => 'Pause token';

  @override
  String get onboardingPauseBody =>
      'Give this to your bank so it can hold transfers during a scam call.';

  @override
  String get onboardingLinkTitle => 'Link code';

  @override
  String get onboardingLinkBody =>
      'Up to 3 family members can enter this code in their own Jaga app.';

  @override
  String onboardingLinkShareText(String code, String name) {
    return 'Open Jaga, choose \"A family co-pilot\" and enter $code to get alerts about $name.';
  }

  @override
  String get onboardingJoined => 'Joined so far';

  @override
  String get onboardingJoinedNone => 'No one yet';

  @override
  String get onboardingBuzzTitle => 'Feel the buzz';

  @override
  String get onboardingBuzzBody =>
      'When the phone buzzes like this during a call, look at the screen.';

  @override
  String get onboardingBuzzButton => 'Feel the buzz';

  @override
  String get onboardingDoneProtected => 'Jaga is set up.';

  @override
  String get onboardingFinish => 'Finish';

  @override
  String get onboardingJoinCode => 'Enter the 6-digit code';

  @override
  String get onboardingNamesTitle => 'A few details';

  @override
  String get onboardingYourName => 'Your name';

  @override
  String get onboardingCallHer => 'Her nickname';

  @override
  String get onboardingCallHerHelper => 'What do you call her?';

  @override
  String get onboardingCodeWrong =>
      'That code doesn\'t match. Check the 6 digits.';

  @override
  String get onboardingCodeExpired =>
      'This code has expired. Ask for a new one.';

  @override
  String get onboardingCopilotsFull =>
      '3 family co-pilots are already linked. One must unlink before you can join.';

  @override
  String get onboardingNotifTitle => 'Allow alerts';

  @override
  String get onboardingNotifBody =>
      'Jaga sends an alert here when someone you look after may be on a scam call.';

  @override
  String get onboardingNotNow => 'Not now';

  @override
  String onboardingDoneCopilot(String name) {
    return 'You\'ll get alerts about $name.';
  }

  @override
  String get statusFamilyLabel => 'Your family';

  @override
  String get statusFamilyNone => 'No family linked yet';

  @override
  String get statusNeedsFamily => 'Ask your family to check Jaga';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPinTitle => 'Enter the co-pilot lock';

  @override
  String get settingsPinWrong => 'Wrong PIN';

  @override
  String get settingsPinLocked => 'Too many tries. Wait 5 minutes.';

  @override
  String get settingsReset => 'Hold to reset Jaga';
}
