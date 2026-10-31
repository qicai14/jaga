import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/family_alert.dart';
import 'package:jaga/data/models/stage_update.dart';
import 'package:jaga/debug/fixtures/family_alert_fixtures.dart';
import 'package:jaga/debug/fixtures/timeline_fixtures.dart';
import 'package:json_schema/json_schema.dart';

List<File> _json(String dir) => Directory(dir)
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
}
