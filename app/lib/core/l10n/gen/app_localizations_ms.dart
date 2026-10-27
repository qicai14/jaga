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
  String warningOfficialNumberLabel(String agency) {
    return 'Nombor rasmi $agency';
  }

  @override
  String get warningOfficialNumberLabelNoAgency => 'Nombor rasmi';

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

  @override
  String get commonCopy => 'Salin';

  @override
  String get commonCopied => 'Disalin';

  @override
  String get commonShare => 'Kongsi';

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonSkip => 'Langkau';

  @override
  String get commonDelete => 'Padam';

  @override
  String commonPinEntered(int count, int total) {
    return '$count daripada $total digit dimasukkan';
  }

  @override
  String onboardingStepOf(int step, int total) {
    return 'Langkah $step daripada $total';
  }

  @override
  String get onboardingContinue => 'Teruskan';

  @override
  String get onboardingRoleTitle => 'Telefon ini untuk siapa?';

  @override
  String get onboardingRoleProtected => 'Orang yang dilindungi Jaga';

  @override
  String get onboardingRoleProtectedBody =>
      'Panggilan ke telefon ini akan berdering dalam Jaga.';

  @override
  String get onboardingRoleCopilot => 'Co-pilot keluarga';

  @override
  String get onboardingRoleCopilotBody =>
      'Terima amaran tentang orang yang anda jaga.';

  @override
  String get onboardingLanguageTitle =>
      'Bahasa apakah yang patut digunakan untuk amaran?';

  @override
  String get onboardingAppLanguageTitle => 'Pilih bahasa anda';

  @override
  String get onboardingAboutTitle => 'Tentang beliau';

  @override
  String get onboardingNameLabel => 'Apakah panggilan keluarga untuk beliau?';

  @override
  String get onboardingRegionInfo =>
      'Wilayah: Malaysia. Jaga menggunakan nombor rasmi Malaysia.';

  @override
  String get onboardingSettingUp => 'Menyediakan…';

  @override
  String get onboardingNetworkError =>
      'Tidak dapat menghubungi Jaga. Semak internet dan cuba lagi.';

  @override
  String get onboardingPermissionsTitle => 'Kebenaran telefon';

  @override
  String get onboardingFix => 'Betulkan';

  @override
  String get onboardingFixedIt => 'Sudah selesai';

  @override
  String get onboardingPermNotifications => 'Pemberitahuan';

  @override
  String get onboardingPermNotificationsWhy => 'Memaparkan amaran.';

  @override
  String get onboardingPermMicrophone => 'Mikrofon';

  @override
  String get onboardingPermMicrophoneWhy =>
      'Membolehkan Jaga mendengar pemanggil.';

  @override
  String get onboardingPermFullScreen => 'Amaran skrin penuh';

  @override
  String get onboardingPermFullScreenWhy =>
      'Membolehkan amaran memenuhi skrin.';

  @override
  String get onboardingPermCallingAccount => 'Akaun panggilan';

  @override
  String get onboardingPermCallingAccountWhy =>
      'Membolehkan panggilan berdering dalam Jaga.';

  @override
  String get onboardingPermAutostart => 'Mula secara automatik';

  @override
  String get onboardingPermAutostartWhy =>
      'Memastikan Jaga terus berjalan pada telefon Xiaomi.';

  @override
  String get onboardingAfterCallSetup =>
      'Disediakan kemudian bersama panggilan';

  @override
  String get onboardingForwardTitle => 'Majukan panggilan ke Jaga';

  @override
  String get onboardingForwardBody =>
      'Dail kod ini sekali. Panggilan ke telefon ini kemudian akan berdering dalam Jaga.';

  @override
  String get onboardingDialNow => 'Dail sekarang';

  @override
  String get onboardingCheckForwarding => 'Semak pemajuan';

  @override
  String get onboardingForwardDone => 'Saya sudah dail';

  @override
  String get onboardingPinTitle => 'Tetapkan kunci co-pilot';

  @override
  String get onboardingPinBody =>
      'Hanya keluarga boleh menukar tetapan Jaga dengan PIN ini, supaya pemanggil tidak boleh memujuk beliau mematikannya.';

  @override
  String get onboardingPinConfirm => 'Masukkan PIN sekali lagi';

  @override
  String get onboardingPinMismatch => 'PIN tidak sepadan. Tetapkan semula.';

  @override
  String get onboardingPauseTitle => 'Token Pause';

  @override
  String get onboardingPauseBody =>
      'Berikan ini kepada bank anda supaya ia boleh menahan pemindahan semasa panggilan penipuan.';

  @override
  String get onboardingLinkTitle => 'Kod pautan';

  @override
  String get onboardingLinkBody =>
      'Sehingga 3 ahli keluarga boleh memasukkan kod ini dalam aplikasi Jaga mereka.';

  @override
  String onboardingLinkShareText(String code, String name) {
    return 'Buka Jaga, pilih \"Co-pilot keluarga\" dan masukkan $code untuk menerima amaran tentang $name.';
  }

  @override
  String get onboardingJoined => 'Telah menyertai';

  @override
  String get onboardingJoinedNone => 'Belum ada';

  @override
  String get onboardingBuzzTitle => 'Rasai getaran';

  @override
  String get onboardingBuzzBody =>
      'Apabila telefon bergetar begini semasa panggilan, lihat skrin.';

  @override
  String get onboardingBuzzButton => 'Rasai getaran';

  @override
  String get onboardingDoneProtected => 'Jaga sudah disediakan.';

  @override
  String get onboardingFinish => 'Selesai';

  @override
  String get onboardingJoinCode => 'Masukkan kod 6 digit';

  @override
  String get onboardingNamesTitle => 'Sedikit butiran';

  @override
  String get onboardingYourName => 'Nama anda';

  @override
  String get onboardingCallHer => 'Apakah panggilan anda untuk beliau?';

  @override
  String get onboardingCodeWrong => 'Kod itu tidak sepadan. Semak 6 digit itu.';

  @override
  String get onboardingCodeExpired =>
      'Kod ini telah tamat tempoh. Minta kod baharu.';

  @override
  String get onboardingCopilotsFull =>
      '3 co-pilot keluarga sudah dipautkan. Seorang mesti memutuskan pautan sebelum anda boleh menyertai.';

  @override
  String get onboardingNotifTitle => 'Benarkan amaran';

  @override
  String get onboardingNotifBody =>
      'Jaga menghantar amaran di sini apabila orang yang anda jaga mungkin menerima panggilan penipuan.';

  @override
  String get onboardingNotNow => 'Bukan sekarang';

  @override
  String onboardingDoneCopilot(String name) {
    return 'Anda akan menerima amaran tentang $name.';
  }

  @override
  String get statusFamilyLabel => 'Keluarga anda';

  @override
  String get statusFamilyNone => 'Belum ada keluarga dipautkan';

  @override
  String get statusNeedsFamily => 'Minta keluarga anda semak Jaga';

  @override
  String get settingsTitle => 'Tetapan';

  @override
  String get settingsPinTitle => 'Masukkan kunci co-pilot';

  @override
  String get settingsPinWrong => 'PIN salah';

  @override
  String get settingsPinLocked => 'Terlalu banyak cubaan. Tunggu 5 minit.';

  @override
  String get settingsReset => 'Tahan untuk menetapkan semula Jaga';
}
