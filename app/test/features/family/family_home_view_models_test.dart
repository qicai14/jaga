import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/scam_hotline.dart';
import 'package:jaga/data/services/copilot_pause_service.dart';
import 'package:jaga/data/services/dialer_service.dart';
import 'package:jaga/data/services/timeline_service.dart';
import 'package:jaga/debug/fixtures/family_alert_fixtures.dart';
import 'package:jaga/debug/fixtures/timeline_fixtures.dart';
import 'package:jaga/features/family/view_models/clear_pause_view_model.dart';
import 'package:jaga/features/family/view_models/copilot_home_view_model.dart';
import 'package:jaga/features/family/view_models/load_status.dart';
import 'package:jaga/features/family/view_models/stage_timeline_view_model.dart';

void main() {
  group('CopilotHomeViewModel', () {
    late FakeCopilotPauseService pause;
    late FakeTimelineService timeline;
    late CopilotHomeViewModel vm;

    CopilotHomeViewModel build() => vm = CopilotHomeViewModel(
      person: familyPerson,
      pause: pause,
      timeline: timeline,
    );

    setUp(() {
      pause = FakeCopilotPauseService(active: true);
      timeline = fixtureTimelineService();
    });
    tearDown(() => vm.dispose());

    test('loads the pause status and the alerted calls', () async {
      build();
      expect(vm.status, LoadStatus.loading);
      await pumpEventQueue();
      expect(vm.status, LoadStatus.loaded);
      expect(vm.pauseActive, isTrue);
      expect(vm.calls, hasLength(5));
    });

    test('a failed load shows an error, and Try again recovers', () async {
      timeline.offline = true;
      build();
      await pumpEventQueue();
      expect(vm.status, LoadStatus.error);
      timeline.offline = false;
      await vm.load();
      expect(vm.status, LoadStatus.loaded);
      expect(vm.calls, hasLength(5));
    });

    test(
      'a refresh keeps the list on screen and picks up the change',
      () async {
        build();
        await pumpEventQueue();
        await pause.clear();
        final states = <LoadStatus>[];
        vm.addListener(() => states.add(vm.status));
        await vm.load();
        expect(states, everyElement(LoadStatus.loaded));
        expect(vm.pauseActive, isFalse);
      },
    );

    test('markPauseCleared hides the pause at once and notifies', () async {
      build();
      await pumpEventQueue();
      var notified = 0;
      vm.addListener(() => notified++);
      vm.markPauseCleared();
      expect(vm.pauseActive, isFalse);
      expect(notified, 1);
    });

    test('no alerted calls is loaded and empty', () async {
      timeline = FakeTimelineService();
      build();
      await pumpEventQueue();
      expect(vm.status, LoadStatus.loaded);
      expect(vm.calls, isEmpty);
    });
  });

  group('ClearPauseViewModel', () {
    late FakeCopilotPauseService pause;
    late ClearPauseViewModel vm;

    setUp(() {
      pause = FakeCopilotPauseService(active: true);
      vm = ClearPauseViewModel(personName: 'Mum', pause: pause);
    });
    tearDown(() => vm.dispose());

    test('success clears the pause and reports it', () async {
      expect(await vm.clear(), isTrue);
      expect(pause.active, isFalse);
      expect(vm.failed, isFalse);
      expect(vm.busy, isFalse);
    });

    test(
      'failure keeps the pause, flags the error, and a retry works',
      () async {
        pause.offline = true;
        expect(await vm.clear(), isFalse);
        expect(pause.active, isTrue);
        expect(vm.failed, isTrue);
        pause.offline = false;
        expect(await vm.clear(), isTrue);
        expect(vm.failed, isFalse);
      },
    );

    test('is busy while clearing, and a second request is ignored', () async {
      final gate = Completer<void>();
      pause.hold = gate.future;
      final first = vm.clear();
      expect(vm.busy, isTrue);
      expect(await vm.clear(), isFalse);
      gate.complete();
      expect(await first, isTrue);
      expect(vm.busy, isFalse);
    });
  });

  group('StageTimelineViewModel', () {
    late FakeTimelineService timeline;
    late FakeDialerService dialer;
    late StageTimelineViewModel vm;

    setUp(() {
      timeline = fixtureTimelineService();
      dialer = FakeDialerService();
      vm = StageTimelineViewModel(
        call: fixtureCalls().last, // call-1
        timeline: timeline,
        dialer: dialer,
      );
    });
    tearDown(() => vm.dispose());

    test('loads the call events in order', () async {
      await pumpEventQueue();
      expect(vm.status, LoadStatus.loaded);
      expect(vm.events, hasLength(4));
      expect(vm.events.first.at.isBefore(vm.events.last.at), isTrue);
    });

    test('a failed load shows an error, and Try again recovers', () async {
      timeline.offline = true;
      await vm.load();
      expect(vm.status, LoadStatus.error);
      timeline.offline = false;
      await vm.load();
      expect(vm.status, LoadStatus.loaded);
    });

    test('delete removes the timeline', () async {
      expect(await vm.delete(), isTrue);
      expect(timeline.deleted, ['call-1']);
      expect(await timeline.calls(), hasLength(4));
    });

    test(
      'deleting is true while a delete is in flight, and notifies',
      () async {
        final gate = Completer<void>();
        timeline.hold = gate.future;
        final states = <bool>[];
        vm.addListener(() => states.add(vm.deleting));
        final first = vm.delete();
        expect(vm.deleting, isTrue);
        expect(await vm.delete(), isFalse); // a second tap is ignored
        gate.complete();
        expect(await first, isTrue);
        expect(vm.deleting, isFalse);
        expect(states, [true, false]);
        expect(timeline.deleted, ['call-1']);
      },
    );

    test('a failed delete reports false and deletes nothing', () async {
      timeline.offline = true;
      expect(await vm.delete(), isFalse);
      expect(timeline.deleted, isEmpty);
    });

    test('the bottom button dials the scam hotline', () async {
      await vm.callHotline();
      expect(dialer.dialed, [scamHotline]);
    });
  });
}
