import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/alerted_call.dart';
import 'package:jaga/data/models/family_alert.dart';
import 'package:jaga/data/models/stage_update.dart';
import 'package:jaga/data/models/voice_token.dart';
import 'package:jaga/debug/fixtures/family_alert_fixtures.dart';
import 'package:jaga/debug/fixtures/timeline_fixtures.dart';
import 'package:json_schema/json_schema.dart';

List<File> _json(String dir) =>
    Directory(dir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();

void main() {
  final schema = JsonSchema.create(
    jsonDecode(
      File('../contracts/stage-update.schema.json').readAsStringSync(),
    ),
  );

  test('every v1 stage-update fixture validates and parses', () {
    final files = _json('../contracts/fixtures/stage-update');
    expect(files, isNotEmpty);
    for (final f in files) {
      final raw = f.readAsStringSync();
      final result = schema.validate(jsonDecode(raw), validateFormats: true);
      expect(result.isValid, isTrue, reason: '${f.path} ${result.errors}');
      StageUpdate.parse(raw); // through the real model
    }
  });

  test('the debug-gallery timeline fixtures are valid stage updates', () {
    for (final raw in timelineV0Fixtures) {
      final result = schema.validate(jsonDecode(raw), validateFormats: true);
      expect(result.isValid, isTrue, reason: '${result.errors} $raw');
      StageUpdate.parse(raw);
    }
  });

  test('every invalid stage-update fixture fails the schema', () {
    final files = _json('../contracts/fixtures/invalid/stage-update');
    expect(files, isNotEmpty);
    for (final f in files) {
      expect(
        schema
            .validate(jsonDecode(f.readAsStringSync()), validateFormats: true)
            .isValid,
        isFalse,
        reason: f.path,
      );
    }
  });

  // Invalid fixtures the model cannot see: extra properties, or maxItems
  // (the screen clamps quotes to two instead).
  const modelIgnores = {
    'stage-update/counter-move-phrase-id.json',
    'family-alert/three-quotes.json',
    'family-alert/transcript-field.json',
  };
  test('the model rejects every invalid fixture it can see', () {
    var checked = 0;
    for (final f in [
      ..._json('../contracts/fixtures/invalid/stage-update'),
      ..._json('../contracts/fixtures/invalid/family-alert'),
    ]) {
      final name = f.path.replaceAll(r'\', '/').split('/invalid/').last;
      if (modelIgnores.contains(name)) continue;
      final raw = f.readAsStringSync();
      expect(
        () => name.startsWith('family-alert')
            ? FamilyAlert.parse(raw)
            : StageUpdate.parse(raw),
        throwsA(anything),
        reason: name,
      );
      checked++;
    }
    expect(checked, 6);
  });

  group('family-alert', () {
    final familySchema = JsonSchema.create(
      jsonDecode(
        File('../contracts/family-alert.schema.json').readAsStringSync(),
      ),
    );

    test('every v1 family-alert fixture validates and parses', () {
      final files = _json('../contracts/fixtures/family-alert');
      expect(files, isNotEmpty);
      for (final f in files) {
        final raw = f.readAsStringSync();
        final result = familySchema.validate(
          jsonDecode(raw),
          validateFormats: true,
        );
        expect(result.isValid, isTrue, reason: '${f.path} ${result.errors}');
        FamilyAlert.parse(raw);
      }
    });

    test('every invalid family-alert fixture fails the schema', () {
      final files = _json('../contracts/fixtures/invalid/family-alert');
      expect(files, isNotEmpty);
      for (final f in files) {
        expect(
          familySchema
              .validate(jsonDecode(f.readAsStringSync()), validateFormats: true)
              .isValid,
          isFalse,
          reason: f.path,
        );
      }
    });

    test('the debug-gallery family fixtures stay valid', () {
      for (final raw in familyAlertFixtures) {
        final result = familySchema.validate(
          jsonDecode(raw),
          validateFormats: true,
        );
        expect(result.isValid, isTrue, reason: '${result.errors} $raw');
        FamilyAlert.parse(raw);
      }
    });
  });

  group('voice-token', () {
    final voiceSchema = JsonSchema.create(
      jsonDecode(
        File('../contracts/voice-token.schema.json').readAsStringSync(),
      ),
    );

    test('every v1 voice-token fixture validates and parses', () {
      final files = _json('../contracts/fixtures/voice-token');
      expect(files, isNotEmpty);
      for (final f in files) {
        final raw = f.readAsStringSync();
        final result = voiceSchema.validate(
          jsonDecode(raw),
          validateFormats: true,
        );
        expect(result.isValid, isTrue, reason: '${f.path} ${result.errors}');
        VoiceToken.parse(raw);
      }
    });

    test('every invalid voice-token fixture fails the schema', () {
      final files = _json('../contracts/fixtures/invalid/voice-token');
      expect(files, isNotEmpty);
      for (final f in files) {
        expect(
          voiceSchema
              .validate(jsonDecode(f.readAsStringSync()), validateFormats: true)
              .isValid,
          isFalse,
          reason: f.path,
        );
      }
    });
  });

  group('stage-timeline, list and pause', () {
    Map<String, dynamic> load(String name) =>
        jsonDecode(File('../contracts/$name.schema.json').readAsStringSync());
    final timelineSchema = JsonSchema.create(load('stage-timeline'));
    final listSchema = JsonSchema.create(
      load('stage-timeline-list'),
      refProvider: RefProvider.sync(
        (ref) => ref.endsWith('stage-timeline') ? load('stage-timeline') : null,
      ),
    );
    final pauseSchema = JsonSchema.create(
      load('pause'),
    ); // the root is the response

    void validAndInvalid(
      String dir,
      JsonSchema schema,
      void Function(dynamic) parse,
    ) {
      test('every valid $dir fixture validates and parses', () {
        final files = _json('../contracts/fixtures/$dir');
        expect(files, isNotEmpty);
        for (final f in files) {
          final json = jsonDecode(f.readAsStringSync());
          final result = schema.validate(json, validateFormats: true);
          expect(result.isValid, isTrue, reason: '${f.path} ${result.errors}');
          parse(json);
        }
      });
      test('every invalid $dir fixture fails the schema', () {
        final files = _json('../contracts/fixtures/invalid/$dir');
        expect(files, isNotEmpty);
        for (final f in files) {
          expect(
            schema
                .validate(
                  jsonDecode(f.readAsStringSync()),
                  validateFormats: true,
                )
                .isValid,
            isFalse,
            reason: f.path,
          );
        }
      });
    }

    void parseTimeline(dynamic j) {
      AlertedCall.fromJson(j);
      for (final e in j['events']) {
        TimelineEvent.fromJson(e);
      }
    }

    validAndInvalid('stage-timeline', timelineSchema, parseTimeline);
    validAndInvalid(
      'stage-timeline-list',
      listSchema,
      (j) => (j as List).forEach(parseTimeline),
    );
    // The pause fixtures also hold the request body, which is not a response.
    test('every pause response fixture validates; invalid ones fail', () {
      for (final f in _json('../contracts/fixtures/pause')) {
        if (f.path.contains('request')) continue;
        final r = pauseSchema.validate(
          jsonDecode(f.readAsStringSync()),
          validateFormats: true,
        );
        expect(r.isValid, isTrue, reason: '${f.path} ${r.errors}');
      }
      for (final f in _json('../contracts/fixtures/invalid/pause')) {
        if (f.path.contains('request')) continue;
        expect(
          pauseSchema
              .validate(jsonDecode(f.readAsStringSync()), validateFormats: true)
              .isValid,
          isFalse,
          reason: f.path,
        );
      }
    });
  });
}
