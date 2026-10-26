import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/haptics/fake_buzzer.dart';
import 'package:jaga/data/models/stage_update.dart';
import 'package:jaga/data/repositories/call_risk_repository.dart';
import 'package:jaga/data/services/attention_service.dart';
import 'package:jaga/data/services/stage_stream_service.dart';
import 'package:jaga/debug/fixtures/stage_update_extended_fixtures.dart';
import 'package:jaga/debug/fixtures/stage_update_fixtures.dart';
import 'package:jaga/features/warning/view_models/warning_view_model.dart';

StageUpdate u(String raw) => StageUpdate.parse(raw);

void main() {
  late FakeStageStreamService stream;
  late FakeBuzzer buzzer;
  late FakeAttentionService attention;
  late WarningViewModel vm;

  setUp(() {
    stream = FakeStageStreamService();
    buzzer = FakeBuzzer();
    attention = FakeAttentionService();
    vm = WarningViewModel(
      repository: CallRiskRepository(stream),
      buzzer: buzzer,
      attention: attention,
    );
  });

  tearDown(() {
    vm.dispose();
    stream.dispose();
  });

  WarningLayer layer() => vm.state.layer;

  test('low shows nothing and does not buzz', () {
    stream.emit(u(stageLow));
    expect(layer(), WarningLayer.none);
    expect(buzzer.calls, isEmpty);
  });

  test('medium is a Caution with no buzz', () {
    stream.emit(u(stageMedium));
    expect(layer(), WarningLayer.caution);
    expect(buzzer.calls, isEmpty);
  });

  test('high is a Warning and starts the buzz', () {
    stream.emit(u(extHigh));
    expect(layer(), WarningLayer.warning);
    expect(buzzer.startCount, 1);
    expect(vm.state.content.isCredentials, isFalse);
  });

  test('stage credentials at high is the credentials variant', () {
    stream.emit(u(extHighCredentials));
    expect(vm.state.content.isCredentials, isTrue);
  });

  test(
    'high with no command is still a Warning (the view shows the fallback)',
    () {
      stream.emit(u(stageHighNoCommand));
      expect(layer(), WarningLayer.warning);
      expect(vm.state.content.command, isNull);
    },
  );

  test('high to medium steps down and stops the buzz; medium to low hides', () {
    stream.emit(u(extHigh));
    stream.emit(u(stageMedium));
    expect(layer(), WarningLayer.caution);
    expect(buzzer.buzzing, isFalse);
    stream.emit(u(stageLow));
    expect(layer(), WarningLayer.none);
  });

  test('dismiss hides locally; a different stage brings it back', () {
    stream.emit(u(extHigh));
    vm.dismiss();
    expect(layer(), WarningLayer.none);
    expect(buzzer.buzzing, isFalse);
    stream.emit(u(extHigh));
    stream.emit(
      u(stageMedium),
    ); // authority is a different stage: re-shows (below)
    expect(layer(), WarningLayer.caution);
  });

  test('dismissed: same stage and same or lower risk stays hidden', () {
    stream.emit(u(stageMedium));
    vm.dismiss();
    stream.emit(u(stageMedium));
    stream.emit(u(stageLow.replaceAll('pretext', 'authority')));
    expect(layer(), WarningLayer.none);
  });

  test('dismissed: a new stage or a higher risk brings it back and buzzes', () {
    stream.emit(u(extHigh));
    vm.dismiss();
    stream.emit(u(extHigh));
    expect(layer(), WarningLayer.none);
    stream.emit(u(extHighCredentials));
    expect(layer(), WarningLayer.warning);
    expect(buzzer.startCount, 2);
  });

  test(
    'risk rise is measured against the previous update, not the dismissal',
    () {
      stream.emit(u(extHigh)); // fear
      stream.emit(u(stageMedium.replaceAll('authority', 'fear')));
      vm.dismiss();
      stream.emit(u(extHigh)); // medium -> high at the same stage
      expect(layer(), WarningLayer.warning);
    },
  );

  test('command change while up swaps content and restarts the buzz', () {
    stream.emit(u(extHigh));
    stream.emit(
      u(extHigh.replaceAll('Letak telefon sekarang.', 'Jangan percaya.')),
    );
    expect(vm.state.content.command, 'Jangan percaya.');
    expect(buzzer.startCount, 2);
  });

  test('same command again does not restart the buzz', () {
    stream.emit(u(extHigh));
    vm.stopBuzz();
    stream.emit(u(extHigh));
    expect(buzzer.startCount, 1);
  });

  test('looked and touch stop the buzz', () {
    stream.emit(u(extHigh));
    attention.lookNow();
    expect(buzzer.buzzing, isFalse);
    stream.emit(u(extHigh.replaceAll('sekarang', 'segera')));
    expect(buzzer.buzzing, isTrue);
    vm.stopBuzz();
    expect(buzzer.buzzing, isFalse);
  });

  test(
    'disconnect freezes layer and content, reconnect applies the latest',
    () {
      stream.emit(u(extHigh));
      stream.setConnected(false);
      expect(vm.state.reconnecting, isTrue);
      stream.emit(u(stageLow));
      expect(layer(), WarningLayer.warning);
      expect(vm.state.content.command, 'Letak telefon sekarang.');
      stream.setConnected(true);
      expect(vm.state.reconnecting, isFalse);
      expect(layer(), WarningLayer.none);
    },
  );

  test('a new callId resets all state and stops the buzz', () {
    stream.emit(u(extHigh));
    vm.dismiss();
    stream.emit(u(extHigh.replaceAll('call-1', 'call-2')));
    expect(layer(), WarningLayer.warning); // dismissal did not carry over
    expect(buzzer.startCount, 2);
  });

  test('reset (call ended) clears the layer and stops the buzz', () {
    stream.emit(u(extHigh));
    vm.reset();
    expect(layer(), WarningLayer.none);
    expect(buzzer.buzzing, isFalse);
  });

  test('repository drops updates for another call', () {
    final other = WarningViewModel(
      repository: CallRiskRepository(stream, callId: 'call-9'),
      buzzer: FakeBuzzer(),
      attention: attention,
    );
    stream.emit(u(extHigh));
    expect(other.state.layer, WarningLayer.none);
    other.dispose();
  });
}
