import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/linked_person.dart';
import '../../data/models/onboarding_progress.dart';
import '../../data/services/device_setup_service.dart';
import '../../data/services/onboarding_api_service.dart';
import '../../features/onboarding/view_models/onboarding_view_model.dart';
import '../../features/onboarding/view_models/protected_home_view_model.dart';
import '../../features/onboarding/views/onboarding_screen.dart';
import '../../features/onboarding/views/protected_home_screen.dart';
import '../../features/onboarding/views/protected_settings_screen.dart';
import '../../features/onboarding/views/widgets/pin_gate_sheet.dart';
import '../gallery_entry.dart';
import '../onboarding_rig.dart';

typedef _Arrange = Future<void> Function(
  OnboardingRig rig,
  OnboardingViewModel vm,
);

/// One setup step on a fresh rig of fakes. [arrange] then drives the view model
/// into the state to show (a typed code, a refused code, a pending request).
class _SetupDemo extends StatefulWidget {
  const _SetupDemo(this.start, {this.device, this.arrange});

  final OnboardingProgress start;
  final FakeDeviceSetupService? device;
  final _Arrange? arrange;

  @override
  State<_SetupDemo> createState() => _SetupDemoState();
}

class _SetupDemoState extends State<_SetupDemo> {
  OnboardingRig? _rig;
  OnboardingViewModel? _vm;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final rig = await OnboardingRig.create(
      start: widget.start,
      device: widget.device,
    );
    final vm = rig.onboardingViewModel();
    _rig = rig;
    _vm = vm;
    await widget.arrange?.call(rig, vm);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm?.dispose();
    _rig?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _vm == null ? const SizedBox.shrink() : OnboardingScreen(vm: _vm!);
}

enum _HomeView { status, gate, settings }

/// The protected user's home, the lock sheet or the settings, on a fresh rig.
class _HomeDemo extends StatefulWidget {
  const _HomeDemo(
    this.view, {
    this.device,
    this.family = const [],
    this.locked = false,
  });

  final _HomeView view;
  final FakeDeviceSetupService? device;
  final List<String> family;

  /// Five wrong tries already made.
  final bool locked;

  @override
  State<_HomeDemo> createState() => _HomeDemoState();
}

class _HomeDemoState extends State<_HomeDemo> {
  OnboardingRig? _rig;
  ProtectedHomeViewModel? _vm;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final rig = await OnboardingRig.create(
      start: _protected.copyWith(complete: true),
      device: widget.device,
    );
    rig.api.joined = widget.family;
    await rig.pin.set('1234');
    if (widget.locked) {
      for (var i = 0; i < 5; i++) {
        await rig.pin.verify('0000');
      }
    }
    _rig = rig;
    _vm = rig.protectedHomeViewModel();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm?.dispose();
    _rig?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) return const SizedBox.shrink();
    return switch (widget.view) {
      _HomeView.status => ProtectedHomeScreen(vm: vm),
      _HomeView.gate => Scaffold(body: PinGateSheet(vm: vm)),
      _HomeView.settings => ProtectedSettingsScreen(vm: vm),
    };
  }
}

const _protected = OnboardingProgress(
  role: OnboardingRole.protectedUser,
  personName: 'Mak Cik Aminah',
  registration: fakeRegistration,
);
const _copilot = OnboardingProgress(role: OnboardingRole.copilot);

FakeDeviceSetupService _granted() =>
    FakeDeviceSetupService(state: {for (final i in platformItems) i: true});

GalleryEntry _setup(
  String state,
  OnboardingProgress start, {
  FakeDeviceSetupService? device,
  _Arrange? arrange,
}) => GalleryEntry(
  feature: 'onboarding',
  state: state,
  build: (_) => _SetupDemo(start, device: device, arrange: arrange),
);

GalleryEntry _home(
  String state,
  _HomeView view, {
  FakeDeviceSetupService? device,
  List<String> family = const [],
  bool locked = false,
}) => GalleryEntry(
  feature: 'onboarding',
  state: state,
  build: (_) => _HomeDemo(view, device: device, family: family, locked: locked),
);

Future<void> _refused(OnboardingViewModel vm, String code) async {
  vm.setCode(code);
  await vm.next();
}

List<GalleryEntry> onboardingEntries() => [
  _setup('language', const OnboardingProgress()),
  _setup('role', const OnboardingProgress(step: OnboardingStep.role)),
  _setup(
    'about',
    const OnboardingProgress(
      role: OnboardingRole.protectedUser,
      step: OnboardingStep.about,
    ),
  ),
  _setup(
    'about-loading',
    const OnboardingProgress(
      role: OnboardingRole.protectedUser,
      step: OnboardingStep.about,
    ),
    arrange: (rig, vm) async {
      vm.setName('Mak Cik Aminah');
      rig.api.hold = Completer<void>().future; // never answers
      unawaited(vm.next());
    },
  ),
  _setup(
    'about-error',
    const OnboardingProgress(
      role: OnboardingRole.protectedUser,
      step: OnboardingStep.about,
    ),
    arrange: (rig, vm) async {
      vm.setName('Mak Cik Aminah');
      rig.api.offline = true;
      await vm.next();
    },
  ),
  _setup(
    'perms-all-red',
    _protected.copyWith(step: OnboardingStep.permissions),
  ),
  _setup(
    'perms-mixed',
    _protected.copyWith(step: OnboardingStep.permissions),
    device: FakeDeviceSetupService(state: {SetupItem.notifications: true}),
  ),
  _setup(
    'perms-xiaomi',
    _protected.copyWith(step: OnboardingStep.permissions),
    device: FakeDeviceSetupService(
      xiaomi: true,
      state: {SetupItem.notifications: true},
    ),
  ),
  _setup(
    'perms-all-green',
    _protected.copyWith(step: OnboardingStep.permissions),
    device: _granted(),
  ),
  _setup('forwarding', _protected.copyWith(step: OnboardingStep.forwarding)),
  _setup('pin-set', _protected.copyWith(step: OnboardingStep.pin)),
  _setup(
    'pin-confirm',
    _protected.copyWith(step: OnboardingStep.pin),
    arrange: (_, vm) => vm.submitPin('1234'),
  ),
  _setup(
    'pin-mismatch',
    _protected.copyWith(step: OnboardingStep.pin),
    arrange: (_, vm) async {
      await vm.submitPin('1234');
      await vm.submitPin('1111');
    },
  ),
  _setup('pause-token', _protected.copyWith(step: OnboardingStep.pauseToken)),
  _setup('link-code', _protected.copyWith(step: OnboardingStep.linkCode)),
  _setup(
    'link-code-joined-3',
    _protected.copyWith(step: OnboardingStep.linkCode),
    arrange: (rig, vm) async {
      rig.api.joined = ['Aisyah', 'Daniel', 'Mei Ling'];
      await vm.refreshJoined();
    },
  ),
  _setup('buzz', _protected.copyWith(step: OnboardingStep.buzz)),
  _setup('done', _protected.copyWith(step: OnboardingStep.done)),
  _setup('copilot-language', _copilot.copyWith(step: OnboardingStep.language)),
  _setup('join-empty', _copilot.copyWith(step: OnboardingStep.joinCode)),
  _setup(
    'join-partial',
    _copilot.copyWith(step: OnboardingStep.joinCode),
    arrange: (_, vm) async => vm.setCode('4829'),
  ),
  _setup(
    'join-wrong',
    _copilot.copyWith(step: OnboardingStep.joinCode),
    arrange: (_, vm) => _refused(vm, '999999'),
  ),
  _setup(
    'join-expired',
    _copilot.copyWith(step: OnboardingStep.joinCode),
    arrange: (_, vm) => _refused(vm, '111111'),
  ),
  _setup(
    'join-full',
    _copilot.copyWith(step: OnboardingStep.joinCode),
    arrange: (_, vm) => _refused(vm, '000000'),
  ),
  _setup(
    'join-names',
    _copilot.copyWith(step: OnboardingStep.joinCode),
    arrange: (_, vm) => _refused(vm, fakeLinkCode),
  ),
  _setup(
    'notifications',
    _copilot.copyWith(step: OnboardingStep.notifications),
  ),
  _setup(
    'notifications-granted',
    _copilot.copyWith(step: OnboardingStep.notifications),
    device: _granted(),
  ),
  _setup(
    'copilot-done',
    _copilot.copyWith(
      step: OnboardingStep.done,
      link: const LinkedPerson(name: 'Mak Cik Aminah'),
    ),
  ),
  _home(
    'status',
    _HomeView.status,
    device: _granted(),
    family: ['Aisyah', 'Daniel'],
  ),
  _home('status-no-family', _HomeView.status, device: _granted()),
  _home(
    'status-needs-attention',
    _HomeView.status,
    family: ['Aisyah', 'Daniel'],
  ),
  _home('pin-gate', _HomeView.gate),
  _home('pin-locked', _HomeView.gate, locked: true),
  _home('settings', _HomeView.settings, family: ['Aisyah']),
];
