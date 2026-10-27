import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/family_alert.dart';
import 'package:jaga/data/models/stage_update.dart';
import 'package:jaga/debug/fixtures/family_alert_fixtures.dart';
import 'package:jaga/debug/fixtures/stage_update_fixtures.dart';
import 'package:jaga/debug/fixtures/timeline_fixtures.dart';
import 'package:json_schema/json_schema.dart';

void main() {
  final schema = JsonSchema.create(
    jsonDecode(
      File('../contracts/stage-update.schema.json').readAsStringSync(),
    ),
  );

  test('every v0 stage-update fixture validates and parses', () {
    for (final raw in [...stageUpdateV0Fixtures, ...timelineV0Fixtures]) {
      final result = schema.validate(jsonDecode(raw));
      expect(result.isValid, isTrue, reason: '${result.errors}\n$raw');
      StageUpdate.parse(raw); // through the real model
    }
  });

  test('the schema really rejects unknown fields (so extended fixtures stay separate)', () {
    final extra = jsonDecode(stageHigh) as Map<String, dynamic>
      ..['officialNumber'] = '999';
    expect(schema.validate(extra).isValid, isFalse);
  });

  group('family-alert', () {
    final familySchema = JsonSchema.create(
      jsonDecode(
        File('../contracts/family-alert.schema.json').readAsStringSync(),
      ),
    );

    test('every v0 family-alert fixture validates and parses', () {
      for (final raw in familyAlertV0Fixtures) {
        final result = familySchema.validate(jsonDecode(raw));
        expect(result.isValid, isTrue, reason: '${result.errors}\n$raw');
        FamilyAlert.parse(raw);
      }
    });

    test(
      'the may-be-genuine fixture is ahead of v0 (kind), so it stays separate',
      () {
        expect(
          familySchema.validate(jsonDecode(familyMayBeGenuine)).isValid,
          isFalse,
        );
      },
    );
  });
}
