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

  group('contract if/then/else', () {
    String update(String risk, String extra) =>
        '{"callId":"c","stage":"fear","risk":"$risk","source":"rules",'
        '"at":"2026-10-27T10:00:00Z"$extra}';
    const both = ',"command":"Letak telefon.","counterMove":"Call 997."';

    test('high needs a non-empty command and counterMove', () {
      expect(StageUpdate.parse(update('high', both)).command, isNotNull);
      for (final extra in [
        '',
        ',"counterMove":"Call 997."',
        ',"command":"Letak telefon."',
        ',"command":"Letak telefon.","counterMove":""',
        ',"command":null,"counterMove":null',
      ]) {
        expect(
          () => StageUpdate.parse(update('high', extra)),
          throwsFormatException,
          reason: extra,
        );
      }
    });

    test('low and medium carry no command or counterMove', () {
      for (final risk in ['low', 'medium']) {
        expect(
          () => StageUpdate.parse(update(risk, ',"command":"x"')),
          throwsFormatException,
        );
        expect(
          () => StageUpdate.parse(update(risk, both)),
          throwsFormatException,
        );
        expect(
          StageUpdate.parse(update(risk, ',"command":null,"counterMove":null'))
              .command,
          isNull,
        );
      }
    });
  });
}
