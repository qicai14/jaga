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

  @override
  String get commonCopy => '复制';

  @override
  String get commonCopied => '已复制';

  @override
  String get commonShare => '分享';

  @override
  String get commonCancel => '取消';

  @override
  String get commonSkip => '跳过';

  @override
  String get commonDelete => '删除';

  @override
  String commonPinEntered(int count, int total) {
    return '已输入 $count 位，共 $total 位';
  }

  @override
  String onboardingStepOf(int step, int total) {
    return '第 $step 步，共 $total 步';
  }

  @override
  String get onboardingContinue => '继续';

  @override
  String get onboardingRoleTitle => '这部手机是给谁用的？';

  @override
  String get onboardingRoleProtected => '受 Jaga 保护的人';

  @override
  String get onboardingRoleProtectedBody => '打给这部手机的电话会在 Jaga 里响铃。';

  @override
  String get onboardingRoleCopilot => '家庭协助人';

  @override
  String get onboardingRoleCopilotBody => '接收您所照顾之人的警报。';

  @override
  String get onboardingLanguageTitle => '警告应使用哪种语言？';

  @override
  String get onboardingAppLanguageTitle => '选择您的语言';

  @override
  String get onboardingAboutTitle => '关于她';

  @override
  String get onboardingNameLabel => '家人怎么称呼她？';

  @override
  String get onboardingRegionInfo => '地区：马来西亚。Jaga 使用马来西亚的官方电话号码。';

  @override
  String get onboardingSettingUp => '正在设置…';

  @override
  String get onboardingNetworkError => '无法连接 Jaga。请检查网络后重试。';

  @override
  String get onboardingPermissionsTitle => '手机权限';

  @override
  String get onboardingFix => '设置';

  @override
  String get onboardingFixedIt => '我已完成';

  @override
  String get onboardingPermNotifications => '通知';

  @override
  String get onboardingPermNotificationsWhy => '显示警报。';

  @override
  String get onboardingPermMicrophone => '麦克风';

  @override
  String get onboardingPermMicrophoneWhy => '让您能通过 Jaga 通话。';

  @override
  String get onboardingPermFullScreen => '全屏警报';

  @override
  String get onboardingPermFullScreenWhy => '让警告占满整个屏幕。';

  @override
  String get onboardingPermCallingAccount => '通话账户';

  @override
  String get onboardingPermCallingAccountWhy => '让电话在 Jaga 里响铃。';

  @override
  String get onboardingPermAutostart => '自动启动';

  @override
  String get onboardingPermAutostartWhy => '让 Jaga 在小米手机上保持运行。';

  @override
  String get onboardingAfterCallSetup => '稍后随通话功能设置';

  @override
  String get onboardingForwardTitle => '将来电转接到 Jaga';

  @override
  String get onboardingForwardBody => '拨一次这个代码。之后打给这部手机的电话会在 Jaga 里响铃。';

  @override
  String get onboardingDialNow => '立即拨号';

  @override
  String get onboardingCheckForwarding => '检查转接';

  @override
  String get onboardingForwardDone => '我已拨号';

  @override
  String get onboardingPinTitle => '设置家庭协助人锁';

  @override
  String get onboardingPinBody => '只有家人能用这个 PIN 更改 Jaga 的设置，这样来电者就无法哄她把它关掉。';

  @override
  String get onboardingPinConfirm => '请再输入一次 PIN';

  @override
  String get onboardingPinMismatch => '两次 PIN 不一致。请重新设置。';

  @override
  String get onboardingPauseTitle => '暂停令牌';

  @override
  String get onboardingPauseBody => '把它交给银行，这样银行可以在诈骗电话期间暂缓转账。';

  @override
  String get onboardingLinkTitle => '关联码';

  @override
  String get onboardingLinkBody => '最多 3 位家人可以在自己的 Jaga 应用中输入此代码。';

  @override
  String onboardingLinkShareText(String code, String name) {
    return '打开 Jaga，选择“家庭协助人”，输入 $code，即可接收关于$name的警报。';
  }

  @override
  String get onboardingJoined => '已加入';

  @override
  String get onboardingJoinedNone => '暂无';

  @override
  String get onboardingBuzzTitle => '感受震动';

  @override
  String get onboardingBuzzBody => '通话中手机这样震动时，请看屏幕。';

  @override
  String get onboardingBuzzButton => '感受震动';

  @override
  String get onboardingDoneProtected => 'Jaga 已设置好。';

  @override
  String get onboardingFinish => '完成';

  @override
  String get onboardingJoinCode => '输入 6 位代码';

  @override
  String get onboardingNamesTitle => '几项信息';

  @override
  String get onboardingYourName => '您的姓名';

  @override
  String get onboardingCallHer => '您怎么称呼她？';

  @override
  String get onboardingCodeWrong => '代码不匹配。请检查这 6 位数字。';

  @override
  String get onboardingCodeExpired => '此代码已过期。请索取新的代码。';

  @override
  String get onboardingCopilotsFull => '已关联 3 位家庭协助人。需要有人解除关联，您才能加入。';

  @override
  String get onboardingNotifTitle => '允许警报';

  @override
  String get onboardingNotifBody => '当您照顾的人可能正在接听诈骗电话时，Jaga 会在这里向您发送警报。';

  @override
  String get onboardingNotNow => '以后再说';

  @override
  String onboardingDoneCopilot(String name) {
    return '您将收到关于$name的警报。';
  }

  @override
  String get statusFamilyLabel => '您的家人';

  @override
  String get statusFamilyNone => '尚未关联家人';

  @override
  String get statusNeedsFamily => '请让家人检查 Jaga';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsPinTitle => '输入家庭协助人锁';

  @override
  String get settingsPinWrong => 'PIN 错误';

  @override
  String get settingsPinLocked => '尝试次数过多。请等待 5 分钟。';

  @override
  String get settingsReset => '按住以重置 Jaga';
}
