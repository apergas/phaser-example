import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> _dartFiles(String path) => Directory(
  path,
).listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart')).toList();

const _worldFolder = 'lib/layers/domain/world/';
const _internalWorldFiles = {
  'world_state.dart',
  'work.dart',
  'navigation.dart',
  'woodcutting.dart',
  'construction.dart',
  'pick_up_items.dart',
};
final _importPattern = RegExp(r'''import\s+['"]([^'"]+)['"]''');

String _resolveImport(String importer, String target) {
  if (target.startsWith('package:rpg/')) return 'lib/${target.substring('package:rpg/'.length)}';
  if (target.contains(':')) return target;
  return Uri.parse(importer).resolve(target).path;
}

List<String> _internalWorldImportOffenders(Map<String, String> sourcesByPath) {
  return sourcesByPath.entries
      .where((entry) => !entry.key.startsWith(_worldFolder))
      .where(
        (entry) => _importPattern.allMatches(entry.value).any((match) {
          final resolved = _resolveImport(entry.key, match.group(1)!);
          return resolved.startsWith(_worldFolder) && _internalWorldFiles.contains(resolved.split('/').last);
        }),
      )
      .map((entry) => entry.key)
      .toList();
}

void main() {
  test('testWhenScanningTheDomainThenItImportsNoOuterLayerNorPlatformApi', () {
    // given
    final files = _dartFiles('lib/layers/domain');
    final forbidden = RegExp(
      r'''import\s+['"](package:flutter|package:flame|dart:ui|dart:io|'''
      r'''[^'"]*/data/|[^'"]*/presentation/|[^'"]*config/di/)''',
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

  test('testWhenScanningLibThenNoFileOutsideTheWorldImportsItsInternals', () {
    // given
    final sources = {for (final file in _dartFiles('lib')) file.path: file.readAsStringSync()};

    // when
    final offenders = _internalWorldImportOffenders(sources);

    // then
    expect(offenders, isEmpty);
  });

  test('testWhenAFileOutsideTheWorldImportsAnInternalThenItIsReported', () {
    // given
    final sources = {
      'lib/layers/data/level_repository_impl.dart': "import 'package:rpg/layers/domain/world/world_state.dart';",
      'lib/layers/domain/quests/quests.dart': "import '../world/navigation.dart';",
      'lib/layers/domain/usecases/use_case.dart': "import '../world/world.dart';",
      'lib/layers/domain/world/world.dart': "import 'world_state.dart';",
      'lib/layers/domain/world/extensions/player_rules.dart': "import '../navigation.dart';",
    };

    // when
    final offenders = _internalWorldImportOffenders(sources);

    // then
    expect(offenders, ['lib/layers/data/level_repository_impl.dart', 'lib/layers/domain/quests/quests.dart']);
  });
}
