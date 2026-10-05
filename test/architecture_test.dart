import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const List<String> _domainForbidden = [
  'lib/layers/data/',
  'lib/layers/presentation/',
  'lib/core/config/di/',
  'lib/core/services/',
  'package:flutter/',
  'package:flame',
  'package:flutter_bloc/',
  'package:bloc/',
  'dart:ui',
  'dart:io',
  'dart:html',
];

const List<String> _dataForbidden = [
  'lib/layers/presentation/',
  'package:flutter/',
  'package:flame',
  'package:flutter_bloc/',
  'package:bloc/',
  'dart:ui',
];

const List<String> _presentationForbidden = ['lib/layers/data/'];

const List<String> _flameConfined = ['package:flame'];

const List<String> _flameAllowedImporters = [
  'lib/layers/presentation/features/forest/game/',
  'lib/layers/presentation/features/forest/forest_page.dart',
];

const List<String> _coreForbidden = ['lib/layers/'];

const Map<String, List<String>> _coreAllowed = {
  'lib/core/services/navigation/source/navigation_service.dart': [
    'lib/layers/presentation/widgets/custom-button/custom_button.dart',
    'lib/layers/presentation/widgets/custom-popup/custom_pop_up.dart',
  ],
  'lib/core/services/navigation/navify/navify_impl.dart': [
    'lib/layers/presentation/theme/colors/custom_colors.dart',
    'lib/layers/presentation/widgets/custom-button/custom_button.dart',
    'lib/layers/presentation/widgets/custom-popup/custom_pop_up.dart',
  ],
};

final RegExp _importPattern = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

final RegExp _mutableFieldPattern = RegExp(
  r'^  (?!final\b|static\b|const\b|factory\b|return\b|@|//)(?:late\s+)?(?:var\b[^;]*;|[A-Za-z_]\w*(?:<[^;{}()]*>)?\??\s+_?(?!get\b|set\b|operator\b)[a-z]\w*\s*(?:=(?![=>]).*)?;)',
  multiLine: true,
);

List<String> importsOf(String source) => _importPattern.allMatches(source).map((match) => match.group(1)!).toList();

String resolveImport({required String importingFile, required String import}) {
  if (import.startsWith('package:rpg/')) return 'lib/${import.substring('package:rpg/'.length)}';
  if (import.startsWith('package:') || import.startsWith('dart:')) return import;
  return Uri.file(importingFile).resolve(import).path;
}

List<String> mutableFieldsIn(String source) =>
    _mutableFieldPattern.allMatches(source).map((match) => match.group(0)!.trim()).toList();

List<File> dartFilesUnder(String folder) {
  final directory = Directory(folder);
  if (!directory.existsSync()) return [];
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart') && !file.path.endsWith('.config.dart'))
      .toList();
}

Map<String, String> sourcesUnder(String folder) => {
  for (final file in dartFilesUnder(folder)) file.path: file.readAsStringSync(),
};

List<String> confinementViolations({
  required Map<String, String> sources,
  required List<String> confined,
  required List<String> allowedImporters,
}) {
  final found = <String>[];
  for (final entry in sources.entries) {
    if (allowedImporters.any(entry.key.startsWith)) continue;
    for (final import in importsOf(entry.value)) {
      final target = resolveImport(importingFile: entry.key, import: import);
      if (confined.any(target.startsWith)) found.add('${entry.key} -> $target');
    }
  }
  return found;
}

List<String> violations({
  required String folder,
  required List<String> forbidden,
  Map<String, List<String>> allowed = const {},
}) {
  final found = <String>[];
  for (final file in dartFilesUnder(folder)) {
    final path = file.path;
    final allowedTargets = allowed.entries
        .where((entry) => path.startsWith(entry.key))
        .expand((entry) => entry.value)
        .toList();
    for (final import in importsOf(file.readAsStringSync())) {
      final target = resolveImport(importingFile: path, import: import);
      final isForbidden = forbidden.any(target.startsWith);
      final isAllowed = allowedTargets.any(target.startsWith);
      if (isForbidden && !isAllowed) found.add('$path -> $target');
    }
  }
  return found;
}

void main() {
  group('rules', () {
    test('testWhenCheckingLibThenFlameIsOnlyImportedByTheForestGameAndPage', () {
      // given
      final sources = sourcesUnder('lib');

      // when
      final found = confinementViolations(
        sources: sources,
        confined: _flameConfined,
        allowedImporters: _flameAllowedImporters,
      );

      // then
      expect(found, isEmpty);
    });

    test('testWhenCheckingDomainThenItImportsNothingFromDataPresentationOrPlatforms', () {
      // given
      const folder = 'lib/layers/domain';

      // when
      final found = violations(folder: folder, forbidden: _domainForbidden);

      // then
      expect(found, isEmpty);
    });

    test('testWhenCheckingDataThenItNeverImportsPresentationOrFlutter', () {
      // given
      const folder = 'lib/layers/data';

      // when
      final found = violations(folder: folder, forbidden: _dataForbidden);

      // then
      expect(found, isEmpty);
    });

    test('testWhenCheckingPresentationThenItNeverImportsData', () {
      // given
      const folder = 'lib/layers/presentation';

      // when
      final found = violations(folder: folder, forbidden: _presentationForbidden);

      // then
      expect(found, isEmpty);
    });

    test('testWhenCheckingCoreThenItOnlyImportsLayersThroughTheDocumentedExceptions', () {
      // given
      const folder = 'lib/core';

      // when
      final found = violations(folder: folder, forbidden: _coreForbidden, allowed: _coreAllowed);

      // then
      expect(found, isEmpty);
    });

    test('testWhenCheckingEntitiesThenTheyHaveNoMutableFields', () {
      // given
      final files = dartFilesUnder('lib/layers/domain/entities');

      // when
      final found = [
        for (final file in files)
          for (final field in mutableFieldsIn(file.readAsStringSync())) '${file.path}: $field',
      ];

      // then
      expect(found, isEmpty);
    });
  });

  group('checkers', () {
    test('testWhenResolvingARelativeImportThenItIsRelativeToTheImportingFile', () {
      // given
      const importingFile = 'lib/layers/domain/world/world.dart';

      // when
      final target = resolveImport(importingFile: importingFile, import: '../../data/x/y.dart');

      // then
      expect(target, 'lib/layers/data/x/y.dart');
    });

    test('testWhenResolvingAPackageImportOfTheAppThenItPointsIntoLib', () {
      // given
      const import = 'package:rpg/layers/data/x.dart';

      // when
      final target = resolveImport(importingFile: 'lib/main.dart', import: import);

      // then
      expect(target, 'lib/layers/data/x.dart');
    });

    test('testWhenReadingImportsThenImportsAndExportsAreFound', () {
      // given
      const source = "import 'package:flutter/material.dart';\nexport '../a.dart';\npart 'b.dart';\n";

      // when
      final imports = importsOf(source);

      // then
      expect(imports, ['package:flutter/material.dart', '../a.dart']);
    });

    test('testWhenCoreImportsAnUnlistedPresentationFileThenItIsReported', () {
      // given
      final directory = Directory.systemTemp.createTempSync('core_check');
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.path}/navify_like.dart')
        ..writeAsStringSync('''
import 'package:rpg/layers/presentation/widgets/custom-popup/custom_pop_up.dart';
import 'package:rpg/layers/presentation/app/container_app.dart';
''');
      final allowed = {
        file.path: ['lib/layers/presentation/widgets/custom-popup/custom_pop_up.dart'],
      };

      // when
      final found = violations(folder: directory.path, forbidden: _coreForbidden, allowed: allowed);

      // then
      expect(found, ['${file.path} -> lib/layers/presentation/app/container_app.dart']);
    });

    test('testWhenAWidgetOrBlocImportsFlameThenItIsReportedAndGameAndPageAreNot', () {
      // given
      final sources = {
        'lib/layers/presentation/features/forest/widgets/hud.dart': "import 'package:flame/game.dart';\n",
        'lib/layers/presentation/features/forest/bloc/forest_bloc.dart':
            "import 'package:flame_bloc/flame_bloc.dart';\n",
        'lib/layers/presentation/features/forest/game/forest_game.dart': "import 'package:flame/game.dart';\n",
        'lib/layers/presentation/features/forest/forest_page.dart': "import 'package:flame/game.dart';\n",
      };

      // when
      final found = confinementViolations(
        sources: sources,
        confined: _flameConfined,
        allowedImporters: _flameAllowedImporters,
      );

      // then
      expect(found, [
        'lib/layers/presentation/features/forest/widgets/hud.dart -> package:flame/game.dart',
        'lib/layers/presentation/features/forest/bloc/forest_bloc.dart -> package:flame_bloc/flame_bloc.dart',
      ]);
    });

    test('testWhenAnEntityHasVarOrNonFinalFieldsThenTheyAreReported', () {
      // given
      const source = '''
class SampleEntity {
  final double x;
  double y;
  var z = 0;
  static const int limit = 3;
  int get total => 1;
  const SampleEntity({required this.x, required this.y});
  @override
  int get hashCode => Object.hash(x, y);
}
''';

      // when
      final fields = mutableFieldsIn(source);

      // then
      expect(fields, ['double y;', 'var z = 0;']);
    });
  });
}
