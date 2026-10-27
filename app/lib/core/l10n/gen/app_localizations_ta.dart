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
    return '$name ஐ அழைக்கவும்';
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
  String get familyAlertAgencyLabel =>
      'அழைப்பவர் தாங்கள் இவர்கள் என்று கூறுகிறார்';

  @override
  String get familyAlertQuotesLabel => 'அழைப்பவர் கூறியது';

  @override
  String familyAlertCall(String name) {
    return '$name ஐ அழைக்கவும்';
  }

  @override
  String get familyAlertOpenDialer => 'தொலைபேசி செயலியைத் திறக்கவும்';

  @override
  String familyGenuineHeadline(String name) {
    return '$name அழைப்பு உண்மையானதாக இருக்கலாம்';
  }

  @override
  String familyGenuineBody(String name) {
    return 'இந்த அழைப்பு மோசடியாக இருக்க வாய்ப்பு குறைவு என்று Jaga இப்போது நினைக்கிறது. சரிபார்க்க நீங்கள் $name ஐ அழைக்கலாம்.';
  }
}
