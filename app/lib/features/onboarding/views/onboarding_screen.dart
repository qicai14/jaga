import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../../data/models/onboarding_progress.dart';
import '../view_models/onboarding_view_model.dart';
import 'steps/about_step.dart';
import 'steps/buzz_step.dart';
import 'steps/done_step.dart';
import 'steps/join_code_step.dart';
import 'steps/notifications_step.dart';
import 'steps/permissions_step.dart';
import 'steps/pin_step.dart';
import 'steps/role_step.dart';
import 'widgets/forwarding_body.dart';
import 'widgets/language_list.dart';
import 'widgets/link_code_body.dart';
import 'widgets/pause_token_body.dart';

/// Both setup flows: one page per step, one big button at the bottom.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.vm});

  final OnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final progress = vm.progress;
        final protectedUser = progress.role != OnboardingRole.copilot;
        final (title, body) = switch (vm.step) {
          OnboardingStep.language => (
            l.onboardingAppLanguageTitle,
            LanguageList(
              selected: progress.language,
              onSelected: vm.selectLanguage,
            ),
          ),
          OnboardingStep.role => (l.onboardingRoleTitle, RoleStep(vm: vm)),
          OnboardingStep.about => (l.onboardingAboutTitle, AboutStep(vm: vm)),
          OnboardingStep.permissions => (
            l.onboardingPermissionsTitle,
            PermissionsStep(vm: vm),
          ),
          OnboardingStep.forwarding => (
            l.onboardingForwardTitle,
            ForwardingBody(
              code: vm.registration.forwardingCode,
              onDial: vm.dialForwarding,
              onCheck: vm.checkForwarding,
            ),
          ),
          OnboardingStep.pin => (l.onboardingPinTitle, PinStep(vm: vm)),
          OnboardingStep.pauseToken => (
            l.onboardingPauseTitle,
            PauseTokenBody(
              token: vm.registration.pauseToken,
              onShare: vm.shareText,
            ),
          ),
          OnboardingStep.linkCode => (
            l.onboardingLinkTitle,
            LinkCodeBody(
              code: vm.registration.linkCode,
              personName: progress.personName,
              joined: vm.joined,
              onShare: vm.shareText,
            ),
          ),
          OnboardingStep.buzz => (l.onboardingBuzzTitle, BuzzStep(vm: vm)),
          OnboardingStep.done => (
            protectedUser
                ? l.onboardingDoneProtected
                : l.onboardingDoneCopilot(progress.link!.name),
            const DoneStep(),
          ),
          OnboardingStep.joinCode => (
            vm.joinStage == JoinStage.code
                ? l.onboardingJoinCode
                : l.onboardingNamesTitle,
            JoinCodeStep(vm: vm),
          ),
          OnboardingStep.notifications => (
            l.onboardingNotifTitle,
            NotificationsStep(vm: vm),
          ),
        };
        return PopScope(
          canPop: vm.isFirstStep,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) vm.back();
          },
          child: ScreenFrame(
            // The language step has nothing to put in a bar: no title, no back.
            appBar: progress.role == null && !vm.canGoBack
                ? null
                : _SetupAppBar(vm: vm),
            title: title,
            body: body,
            bottomAction: _Actions(vm: vm),
          ),
        );
      },
    );
  }
}

/// Back arrow, and once a role is chosen "Step n of m" and a thin progress bar.
class _SetupAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SetupAppBar({required this.vm});

  final OnboardingViewModel vm;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (vm.progress.role == null ? 0 : 6));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final chosen = vm.progress.role != null;
    return AppBar(
      leading: vm.canGoBack
          ? IconButton(
              style: IconButton.styleFrom(
                minimumSize: Size.square(context.metrics.minTarget),
              ),
              icon: const Icon(Icons.arrow_back),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: vm.back,
            )
          : null,
      automaticallyImplyLeading: false,
      title: chosen
          // The bar is a fixed height, so its text stops growing at 1.5.
          ? MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.5,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(l.onboardingStepOf(vm.stepNumber, vm.stepCount)),
              ),
            )
          : null,
      bottom: chosen
          ? PreferredSize(
              preferredSize: const Size.fromHeight(6),
              child: LinearProgressIndicator(
                value: vm.stepNumber / vm.stepCount,
                minHeight: 6,
                color: context.jagaColors.guarded,
                backgroundColor: scheme.surfaceContainerHigh,
              ),
            )
          : null,
    );
  }
}

/// The step's primary button, and the quiet extra under it when there is one.
class _Actions extends StatelessWidget {
  const _Actions({required this.vm});

  final OnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final step = vm.step;
    final registering = vm.busy && step == OnboardingStep.about;
    final label = registering
        ? l.onboardingSettingUp
        : switch (step) {
            OnboardingStep.forwarding => l.onboardingForwardDone,
            OnboardingStep.done => l.onboardingFinish,
            _ => l.onboardingContinue,
          };
    final extra = switch (step) {
      // Debug builds only: lets the flow run on a phone with no SIM.
      OnboardingStep.forwarding when kDebugMode => l.commonSkip,
      OnboardingStep.notifications => l.onboardingNotNow,
      _ => null,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BigButton(
          label: label,
          busy: vm.busy,
          onPressed: vm.canContinue && !vm.busy ? vm.next : null,
        ),
        if (extra != null) TextButton(onPressed: vm.next, child: Text(extra)),
      ],
    );
  }
}
