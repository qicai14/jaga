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
}
