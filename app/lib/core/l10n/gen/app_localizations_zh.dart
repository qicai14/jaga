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
}
