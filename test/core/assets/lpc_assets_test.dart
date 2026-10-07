import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const String _folder = 'lib/core/assets/images/lpc';

const List<String> _files = [
  'forest.png',
  'forest.json',
  'ground.png',
  'hero-walk.png',
  'hero-idle.png',
  'hero-walk-axe.png',
  'hero-idle-axe.png',
  'hero-chop.png',
  'hero-hammer.png',
  'arena.png',
  'arena.json',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('testWhenLoadingTheLpcArtThenEveryFileIsBundled', () async {
    // given
    final paths = [for (final name in _files) '$_folder/$name'];

    // when
    final sizes = [for (final path in paths) (await rootBundle.load(path)).lengthInBytes];

    // then
    expect(sizes.every((size) => size > 0), isTrue);
  });

  test('testWhenReadingTheForestAtlasThenTheHouseKeepsItsBottomCentrePivot', () async {
    // given
    final json = await rootBundle.loadString('$_folder/forest.json');

    // when
    final frames = (jsonDecode(json) as Map<String, dynamic>)['frames'] as Map<String, dynamic>;
    final house = frames['house'] as Map<String, dynamic>;

    // then
    expect(house['pivot'], {'x': 0.5, 'y': 1});
  });
}
