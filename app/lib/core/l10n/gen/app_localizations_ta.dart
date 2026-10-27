// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'Jaga';

  @override
  String get statusProtected => 'Jaga உங்களைப் பாதுகாக்கிறது';

  @override
  String get statusPauseActive => 'Jaga Pause இயக்கத்தில் உள்ளது';

  @override
  String get callReconnecting => 'மீண்டும் இணைக்கிறது';

  @override
  String get commonHoldHint => '2 விநாடிகள் அழுத்திப் பிடிக்கவும்';

  @override
  String get commonTapAgainHint => 'உறுதிப்படுத்த மீண்டும் தட்டவும்';

  @override
  String get stageLabelPretext => 'அழைப்பதற்கு ஒரு காரணம் கூறினார்';

  @override
  String get stageLabelAuthority => 'அதிகாரி என்று கூறிக்கொண்டார்';

  @override
  String get stageLabelFear => 'உங்களைப் பயமுறுத்தினார்';

  @override
  String get stageLabelIsolation => 'ரகசியமாக வைக்கச் சொன்னார்';

  @override
  String get stageLabelHandoff => 'வேறொருவருக்கு மாற்றினார்';

  @override
  String get stageLabelMoney => 'பணத்தை மாற்றச் சொன்னார்';

  @override
  String get stageLabelCredentials =>
      'குறியீடுகள் அல்லது கடவுச்சொற்களைக் கேட்டார்';

  @override
  String stageStepSemantics(int step, int total, String label) {
    return 'படி $step / $total: $label';
  }

  @override
  String get cautionBannerText => 'இந்த அழைப்பில் மோசடிக்கான அறிகுறிகள் உள்ளன';

  @override
  String get warningSemanticsLabel => 'மோசடி எச்சரிக்கை';

  @override
  String get warningFromJaga => 'Jaga-விடமிருந்து மோசடி எச்சரிக்கை';

  @override
  String warningOfficialNumberLabel(String agency) {
    return '$agency அதிகாரப்பூர்வ எண்';
  }

  @override
  String get warningOfficialNumberLabelNoAgency => 'அதிகாரப்பூர்வ எண்';

  @override
  String get warningEvidenceLabel => 'அழைத்தவர் கூறியது';

  @override
  String get warningHangUp => 'அழைப்பைத் துண்டிக்கவும்';

  @override
  String get warningDismissLabel => 'இந்த அழைப்பு பாதுகாப்பானது';

  @override
  String get warningDismissHint => '2 விநாடிகள் அழுத்திப் பிடிக்கவும்';

  @override
  String get warningDismissConfirmHint =>
      'இந்த அழைப்பு பாதுகாப்பானது என்பதை உறுதிப்படுத்த மீண்டும் தட்டவும்';

  @override
  String get warningCommandFallback => 'Letak telefon. Hang up.';

  @override
  String get familyNotifChannelAlerts => 'மோசடி எச்சரிக்கைகள்';

  @override
  String get familyNotifChannelUpdates => 'அழைப்பு புதுப்பிப்புகள்';

  @override
  String familyNotifTitle(String name) {
    return '$name மோசடி அழைப்பில் இருக்கலாம்';
  }

  @override
  String familyNotifBody(String stage) {
    return '$stage.';
  }

  @override
  String familyNotifBodyAgency(String stage, String agency) {
    return '$stage. $agency என்று கூறுகிறார்கள்.';
  }

  @override
  String familyNotifGenuineTitle(String name) {
    return '$name அழைப்பு உண்மையானதாக இருக்கலாம்';
  }

  @override
  String familyNotifCallAction(String name) {
    return '$nameஐ அழைக்கவும்';
  }

  @override
  String familyAlertHeadline(String name) {
    return '$name மோசடி அழைப்பில் இருக்கலாம்';
  }

  @override
  String familyAlertTime(String time) {
    return 'எச்சரிக்கை நேரம் $time';
  }

  @override
  String get familyAlertAgencyLabel => 'அழைப்பவர் கூறும் அமைப்பு';

  @override
  String get familyAlertQuotesLabel => 'அழைப்பவர் கூறியது';

  @override
  String familyAlertCall(String name) {
    return '$nameஐ அழைக்கவும்';
  }

  @override
  String get familyAlertOpenDialer => 'தொலைபேசி செயலியைத் திறக்கவும்';

  @override
  String familyGenuineHeadline(String name) {
    return '$name அழைப்பு உண்மையானதாக இருக்கலாம்';
  }

  @override
  String familyGenuineBody(String name) {
    return 'இந்த அழைப்பு மோசடியாக இருக்க வாய்ப்பு குறைவு என்று Jaga இப்போது நினைக்கிறது. சரிபார்க்க நீங்கள் $nameஐ அழைக்கலாம்.';
  }

  @override
  String get familyAlertCallShort => 'அழைக்கவும்';

  @override
  String get familyAlertDialFailed => 'தொலைபேசி செயலியைத் திறக்க முடியவில்லை.';

  @override
  String get commonCopy => 'நகலெடு';

  @override
  String get commonCopied => 'நகலெடுக்கப்பட்டது';

  @override
  String get commonShare => 'பகிர்';

  @override
  String get commonCancel => 'ரத்து செய்';

  @override
  String get commonSkip => 'தவிர்';

  @override
  String get commonDelete => 'அழி';

  @override
  String commonPinEntered(int count, int total) {
    return '$total இலக்கங்களில் $count உள்ளிடப்பட்டன';
  }

  @override
  String onboardingStepOf(int step, int total) {
    return 'படி $step / $total';
  }

  @override
  String get onboardingContinue => 'தொடரவும்';

  @override
  String get onboardingRoleTitle => 'இந்த தொலைபேசி யாருக்கானது?';

  @override
  String get onboardingRoleProtected => 'Jaga பாதுகாக்கும் நபர்';

  @override
  String get onboardingRoleProtectedBody =>
      'இந்த தொலைபேசிக்கான அழைப்புகள் Jaga-வில் ஒலிக்கும்.';

  @override
  String get onboardingRoleCopilot => 'குடும்ப உதவியாளர்';

  @override
  String get onboardingRoleCopilotBody =>
      'நீங்கள் கவனித்துக்கொள்ளும் ஒருவரைப் பற்றிய எச்சரிக்கைகளைப் பெறுங்கள்.';

  @override
  String get onboardingLanguageTitle =>
      'எச்சரிக்கைகள் எந்த மொழியில் இருக்க வேண்டும்?';

  @override
  String get onboardingAppLanguageTitle => 'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get onboardingAboutTitle => 'அவரைப் பற்றி';

  @override
  String get onboardingNameLabel => 'அவர் பெயர்';

  @override
  String get onboardingNameHelper => 'குடும்பத்தினர் அவரை என்ன அழைப்பார்கள்?';

  @override
  String get onboardingRegionInfo =>
      'பிராந்தியம்: மலேசியா. Jaga மலேசியாவின் அதிகாரப்பூர்வ எண்களைப் பயன்படுத்துகிறது.';

  @override
  String get onboardingSettingUp => 'அமைக்கிறது…';

  @override
  String get onboardingNetworkError =>
      'Jaga-வை அடைய முடியவில்லை. இணையத்தைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get onboardingPermissionsTitle => 'தொலைபேசி அனுமதிகள்';

  @override
  String get onboardingFix => 'சரிசெய்';

  @override
  String get onboardingFixedIt => 'செய்துவிட்டேன்';

  @override
  String get onboardingPermNotifications => 'அறிவிப்புகள்';

  @override
  String get onboardingPermNotificationsWhy => 'எச்சரிக்கைகளைக் காட்டும்.';

  @override
  String get onboardingPermMicrophone => 'ஒலிவாங்கி';

  @override
  String get onboardingPermMicrophoneWhy =>
      'Jaga மூலம் அழைப்புகளில் பேச உதவும்.';

  @override
  String get onboardingPermFullScreen => 'முழுத்திரை எச்சரிக்கைகள்';

  @override
  String get onboardingPermFullScreenWhy =>
      'எச்சரிக்கை திரை முழுவதும் தோன்ற உதவும்.';

  @override
  String get onboardingPermCallingAccount => 'அழைப்புக் கணக்கு';

  @override
  String get onboardingPermCallingAccountWhy =>
      'அழைப்புகள் Jaga-வில் ஒலிக்க உதவும்.';

  @override
  String get onboardingPermAutostart => 'தானாகத் தொடங்கு';

  @override
  String get onboardingPermAutostartWhy =>
      'Xiaomi தொலைபேசிகளில் Jaga தொடர்ந்து இயங்க உதவும்.';

  @override
  String get onboardingAfterCallSetup => 'அழைப்புகளுடன் பின்னர் அமைக்கப்படும்';

  @override
  String get onboardingForwardTitle =>
      'அழைப்புகளை Jaga-விற்கு திருப்பிவிடுங்கள்';

  @override
  String get onboardingForwardBody =>
      'இந்த குறியீட்டை ஒருமுறை டயல் செய்யுங்கள். பிறகு இந்த தொலைபேசிக்கான அழைப்புகள் Jaga-வில் ஒலிக்கும்.';

  @override
  String get onboardingDialNow => 'இப்போது டயல் செய்';

  @override
  String get onboardingCheckForwarding => 'திருப்புதலைச் சரிபார்';

  @override
  String get onboardingForwardDone => 'டயல் செய்துவிட்டேன்';

  @override
  String get onboardingPinTitle => 'துணை பூட்டை அமைக்கவும்';

  @override
  String get onboardingPinBody =>
      'இந்த PIN மூலம் குடும்பத்தினர் மட்டுமே Jaga அமைப்புகளை மாற்ற முடியும்; அதனால் அழைப்பவர் அவரை அதை அணைக்கச் சொல்லி ஏமாற்ற முடியாது.';

  @override
  String get onboardingPinConfirm => 'PIN-ஐ மீண்டும் உள்ளிடவும்';

  @override
  String get onboardingPinMismatch =>
      'PIN-கள் பொருந்தவில்லை. மீண்டும் அமைக்கவும்.';

  @override
  String get onboardingPauseTitle => 'Pause டோக்கன்';

  @override
  String get onboardingPauseBody =>
      'மோசடி அழைப்பின் போது பரிமாற்றங்களை நிறுத்த, இதை உங்கள் வங்கியிடம் கொடுங்கள்.';

  @override
  String get onboardingLinkTitle => 'இணைப்புக் குறியீடு';

  @override
  String get onboardingLinkBody =>
      '3 குடும்ப உறுப்பினர்கள் வரை தங்கள் Jaga செயலியில் இந்தக் குறியீட்டை உள்ளிடலாம்.';

  @override
  String onboardingLinkShareText(String code, String name) {
    return 'Jaga-வைத் திறந்து, \"குடும்ப உதவியாளர்\" என்பதைத் தேர்ந்தெடுத்து, $name பற்றிய எச்சரிக்கைகளைப் பெற $code ஐ உள்ளிடவும்.';
  }

  @override
  String get onboardingJoined => 'இதுவரை சேர்ந்தவர்கள்';

  @override
  String get onboardingJoinedNone => 'இன்னும் யாரும் இல்லை';

  @override
  String get onboardingBuzzTitle => 'அதிர்வை உணருங்கள்';

  @override
  String get onboardingBuzzBody =>
      'அழைப்பின் போது தொலைபேசி இப்படி அதிர்ந்தால், திரையைப் பாருங்கள்.';

  @override
  String get onboardingBuzzButton => 'அதிர்வை உணருங்கள்';

  @override
  String get onboardingDoneProtected => 'Jaga அமைக்கப்பட்டது.';

  @override
  String get onboardingFinish => 'முடி';

  @override
  String get onboardingJoinCode => '6 இலக்கக் குறியீட்டை உள்ளிடவும்';

  @override
  String get onboardingNamesTitle => 'சில விவரங்கள்';

  @override
  String get onboardingYourName => 'உங்கள் பெயர்';

  @override
  String get onboardingCallHer => 'அவரை அழைக்கும் பெயர்';

  @override
  String get onboardingCallHerHelper => 'நீங்கள் அவரை என்ன அழைப்பீர்கள்?';

  @override
  String get onboardingCodeWrong =>
      'அந்தக் குறியீடு பொருந்தவில்லை. 6 இலக்கங்களையும் சரிபார்க்கவும்.';

  @override
  String get onboardingCodeExpired =>
      'இந்தக் குறியீடு காலாவதியாகிவிட்டது. புதியதைக் கேளுங்கள்.';

  @override
  String get onboardingCopilotsFull =>
      '3 குடும்ப உதவியாளர்கள் ஏற்கெனவே இணைக்கப்பட்டுள்ளனர். நீங்கள் சேர ஒருவர் இணைப்பை நீக்க வேண்டும்.';

  @override
  String get onboardingNotifTitle => 'எச்சரிக்கைகளை அனுமதிக்கவும்';

  @override
  String get onboardingNotifBody =>
      'நீங்கள் கவனித்துக்கொள்ளும் ஒருவர் மோசடி அழைப்பில் இருக்கலாம் என்றால், Jaga இங்கே எச்சரிக்கை அனுப்பும்.';

  @override
  String get onboardingNotNow => 'இப்போது வேண்டாம்';

  @override
  String onboardingDoneCopilot(String name) {
    return '$name பற்றிய எச்சரிக்கைகளைப் பெறுவீர்கள்.';
  }

  @override
  String get statusFamilyLabel => 'உங்கள் குடும்பம்';

  @override
  String get statusFamilyNone => 'இன்னும் குடும்பத்தினர் இணைக்கப்படவில்லை';

  @override
  String get statusNeedsFamily =>
      'உங்கள் குடும்பத்தினரிடம் Jaga-வைச் சரிபார்க்கச் சொல்லுங்கள்';

  @override
  String get settingsTitle => 'அமைப்புகள்';

  @override
  String get settingsPinTitle => 'துணை பூட்டை உள்ளிடவும்';

  @override
  String get settingsPinWrong => 'தவறான PIN';

  @override
  String get settingsPinLocked =>
      'அதிக முறை முயற்சித்துவிட்டீர்கள். 5 நிமிடங்கள் காத்திருக்கவும்.';

  @override
  String get settingsReset => 'Jaga-வை மீட்டமைக்க அழுத்திப் பிடிக்கவும்';
}
