import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/atlas_frame.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/lpc_atlas.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/sprite_names.dart';

import '../../../../../../mocks/presentation/features/forest/game/lpc_atlas_source_mock.dart';

void main() {
  test('testWhenParsingTheAtlasThenReadsRectanglesAndPivots', () {
    // given
    const source = LpcAtlasSourceMock.source;

    // when
    final frames = LpcAtlas.parse(source);

    // then
    expect(
      frames['house'],
      const AtlasFrame(name: 'house', x: 0, y: 0, width: 120, height: 191, pivotX: 0.5, pivotY: 1),
    );
    expect(
      frames['tree-old'],
      const AtlasFrame(name: 'tree-old', x: 122, y: 0, width: 150, height: 169, pivotX: 0.4067, pivotY: 0.9941),
    );
  });

  test('testWhenAFrameHasNoPivotThenUsesTheCentre', () {
    // given
    const source = LpcAtlasSourceMock.source;

    // when
    final frame = LpcAtlas.parse(source)['no-pivot'];

    // then
    expect(frame, const AtlasFrame(name: 'no-pivot', x: 1, y: 2, width: 3, height: 4, pivotX: 0.5, pivotY: 0.5));
  });

  test('testWhenParsingTheGeneratedAtlasThenEveryLevelSpriteExists', () {
    // given
    final source = File('lib/core/assets/images/lpc/forest.json').readAsStringSync();
    final expected = [
      SpriteNames.house,
      SpriteNames.stump,
      SpriteNames.axePickup,
      for (final kind in TreeKind.values) SpriteNames.tree(kind),
      for (final kind in DecorationKind.values) SpriteNames.decoration(kind),
    ];

    // when
    final frames = LpcAtlas.parse(source);

    // then
    expect(frames.keys, containsAll(expected));
  });
}
