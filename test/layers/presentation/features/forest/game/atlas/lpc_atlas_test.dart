import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/lpc_atlas.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/sprite_names.dart';

import '../../../../../../mocks/presentation/features/forest/game/atlas_frame_mock.dart';
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
      AtlasFrameMock.house,
    );
    expect(
      frames['tree-old'],
      AtlasFrameMock.treeOld,
    );
  });

  test('testWhenAFrameHasNoPivotThenUsesTheCentre', () {
    // given
    const source = LpcAtlasSourceMock.source;

    // when
    final frame = LpcAtlas.parse(source)['no-pivot'];

    // then
    expect(frame, AtlasFrameMock.noPivot);
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
