import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> _dartFiles(String path) => Directory(
  path,
).listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart')).toList();

void main() {
  test('testWhenScanningTheDomainThenItImportsNoOuterLayerNorPlatformApi', () {
    // given
    final files = _dartFiles('lib/layers/domain');
    final forbidden = RegExp(
      r'''import\s+['"](package:flutter|package:flame|dart:ui|dart:io|[^'"]*/data/|[^'"]*/presentation/|[^'"]*config/di/)''',
    );

    // when
    final offenders = files.where((file) => forbidden.hasMatch(file.readAsStringSync())).map((file) => file.path);

    // then
    expect(offenders, isEmpty);
  });

  test('testWhenScanningEntitiesThenEveryFieldIsFinal', () {
    // given
    final files = _dartFiles('lib/layers/domain/entities');
    final mutableField = RegExp(r'^  (?![ })\]])(?!final |static |const )(?!.*(\(|=>)).*;$', multiLine: true);

    // when
    final offenders = files.where((file) => mutableField.hasMatch(file.readAsStringSync())).map((file) => file.path);

    // then
    expect(offenders, isEmpty);
  });
}
