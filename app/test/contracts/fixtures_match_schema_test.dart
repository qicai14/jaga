import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/stage_update.dart';
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
}
