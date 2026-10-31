// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appTitle => 'Jaga';

  @override
  String get statusProtected => 'Jaga sedang melindungi anda';

  @override
  String get statusPauseActive => 'Jaga Pause aktif';

  @override
  String get callReconnecting => 'Menyambung semula';

  @override
  String get commonHoldHint => 'Tekan dan tahan selama 2 saat';

  @override
  String get commonTapAgainHint => 'Ketik sekali lagi untuk mengesahkan';

  @override
  String get stageLabelPretext => 'Memberi sebab untuk menelefon';

  @override
  String get stageLabelAuthority => 'Mengaku sebagai pegawai';

  @override
  String get stageLabelFear => 'Menakutkan anda';

  @override
  String get stageLabelIsolation => 'Disuruh merahsiakan';

  @override
  String get stageLabelHandoff => 'Dipindahkan kepada orang lain';

  @override
  String get stageLabelMoney => 'Disuruh memindahkan wang';

  @override
  String get stageLabelCredentials => 'Diminta kod atau kata laluan';

  @override
  String stageStepSemantics(int step, int total, String label) {
    return 'Langkah $step daripada $total: $label';
  }

  @override
  String get cautionBannerText => 'Panggilan ini ada tanda penipuan';

  @override
  String get warningSemanticsLabel => 'Amaran penipuan';

  @override
  String get warningFromJaga => 'Amaran penipuan daripada Jaga';

  @override
  String get warningEvidenceLabel => 'Pemanggil berkata';

  @override
  String get warningHangUp => 'Letak telefon';

  @override
  String get warningDismissLabel => 'Panggilan ini selamat';

  @override
  String get warningDismissHint => 'Tekan dan tahan selama 2 saat';

  @override
  String get warningDismissConfirmHint =>
      'Ketik sekali lagi untuk mengesahkan panggilan ini selamat';

  @override
  String get warningCommandFallback => 'Letak telefon. Hang up.';

  @override
  String get familyNotifChannelAlerts => 'Amaran penipuan';

  @override
  String get familyNotifChannelUpdates => 'Kemas kini panggilan';

  @override
  String familyNotifTitle(String name) {
    return '$name mungkin menerima panggilan penipuan';
  }

  @override
  String familyNotifBody(String stage) {
    return '$stage.';
  }

  @override
  String familyNotifBodyAgency(String stage, String agency) {
    return '$stage. Mengaku daripada $agency.';
  }

  @override
  String familyNotifGenuineTitle(String name) {
    return 'Panggilan $name mungkin sah';
  }

  @override
  String familyNotifCallAction(String name) {
    return 'Telefon $name';
  }

  @override
  String familyAlertHeadline(String name) {
    return '$name mungkin menerima panggilan penipuan';
  }

  @override
  String familyAlertTime(String time) {
    return 'Amaran pada $time';
  }

  @override
  String get familyAlertAgencyLabel => 'Pemanggil mengaku daripada';

  @override
  String get familyAlertQuotesLabel => 'Pemanggil berkata';

  @override
  String familyAlertCall(String name) {
    return 'Telefon $name';
  }

  @override
  String get familyAlertOpenDialer => 'Buka aplikasi telefon';

  @override
  String familyGenuineHeadline(String name) {
    return 'Panggilan $name mungkin sah';
  }

  @override
  String familyGenuineBody(String name) {
    return 'Jaga kini berpendapat panggilan ini kurang berkemungkinan penipuan. Anda masih boleh menelefon $name untuk menyemak.';
  }

  @override
  String get familyAlertCallShort => 'Telefon';

  @override
  String get familyAlertDialFailed => 'Tidak dapat membuka aplikasi telefon.';
}
