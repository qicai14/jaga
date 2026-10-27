// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Jaga';

  @override
  String get statusProtected => 'Jaga 正在保护您';

  @override
  String get statusPauseActive => 'Jaga 暂停已开启';

  @override
  String get callReconnecting => '正在重新连接';

  @override
  String get commonHoldHint => '按住 2 秒';

  @override
  String get commonTapAgainHint => '再点一次以确认';

  @override
  String get stageLabelPretext => '给出了来电理由';

  @override
  String get stageLabelAuthority => '自称是官员';

  @override
  String get stageLabelFear => '让您感到害怕';

  @override
  String get stageLabelIsolation => '要求您保密';

  @override
  String get stageLabelHandoff => '转给了另一个人';

  @override
  String get stageLabelMoney => '要求转账';

  @override
  String get stageLabelCredentials => '索要验证码或密码';

  @override
  String stageStepSemantics(int step, int total, String label) {
    return '第 $step 步，共 $total 步：$label';
  }

  @override
  String get cautionBannerText => '这通电话有诈骗迹象';

  @override
  String get warningSemanticsLabel => '诈骗警告';

  @override
  String get warningFromJaga => '来自 Jaga 的诈骗警告';

  @override
  String warningOfficialNumberLabel(String agency) {
    return '$agency的官方电话';
  }

  @override
  String get warningOfficialNumberLabelNoAgency => '官方电话';

  @override
  String get warningEvidenceLabel => '来电者说';

  @override
  String get warningHangUp => '挂断';

  @override
  String get warningDismissLabel => '这通电话没问题';

  @override
  String get warningDismissHint => '按住 2 秒';

  @override
  String get warningDismissConfirmHint => '再点一次，确认这通电话没问题';

  @override
  String get warningCommandFallback => 'Letak telefon. Hang up.';

  @override
  String get familyNotifChannelAlerts => '诈骗警报';

  @override
  String get familyNotifChannelUpdates => '通话更新';

  @override
  String familyNotifTitle(String name) {
    return '$name可能正在接听诈骗电话';
  }

  @override
  String familyNotifBody(String stage) {
    return '$stage。';
  }

  @override
  String familyNotifBodyAgency(String stage, String agency) {
    return '$stage。自称来自$agency。';
  }

  @override
  String familyNotifGenuineTitle(String name) {
    return '$name的来电可能是真实的';
  }

  @override
  String familyNotifCallAction(String name) {
    return '致电$name';
  }

  @override
  String familyAlertHeadline(String name) {
    return '$name可能正在接听诈骗电话';
  }

  @override
  String familyAlertTime(String time) {
    return '警报时间 $time';
  }

  @override
  String get familyAlertAgencyLabel => '来电者自称来自';

  @override
  String get familyAlertQuotesLabel => '来电者说';

  @override
  String familyAlertCall(String name) {
    return '致电$name';
  }

  @override
  String get familyAlertOpenDialer => '打开电话应用';

  @override
  String familyGenuineHeadline(String name) {
    return '$name的来电可能是真实的';
  }

  @override
  String familyGenuineBody(String name) {
    return 'Jaga 现在认为这通电话不太可能是诈骗。您仍可以致电$name确认。';
  }

  @override
  String get familyAlertCallShort => '致电';

  @override
  String get familyAlertDialFailed => '无法打开电话应用。';
}
