import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/stage.dart';
import 'package:jaga/data/models/stage_update.dart';
import 'package:jaga/debug/fixtures/stage_update_fixtures.dart';

void main() {
  test('parses a v1 update', () {
    final s = StageUpdate.parse(stageHigh);
    expect(s.stage, Stage.fear);
    expect(s.risk, Risk.high);
    expect(s.source, Source.rules);
    expect(s.claimedAgency, 'PDRM');
    expect(s.evidence, hasLength(1));
  });

  test('optional fields may be missing', () {
    final s = StageUpdate.parse(
      '{"callId":"c","stage":"none","risk":"low","source":"rules","at":"2026-10-27T10:00:00Z"}',
    );
    expect(s.evidence, isEmpty);
    expect(s.command, isNull);
  });

  test('unknown enum values throw (contract drift)', () {
    expect(
      () => StageUpdate.parse(
        '{"callId":"c","stage":"x","risk":"low","source":"rules","at":"2026-10-27T10:00:00Z"}',
      ),
      throwsStateError,
    );
  });
}
