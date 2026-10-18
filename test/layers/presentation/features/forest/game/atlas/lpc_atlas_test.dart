import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/decoration_kind.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/layers/presentation/features/forest/game/atlas/lpc_atlas.dart';
import 'package:farming/layers/presentation/features/forest/game/atlas/sprite_names.dart';

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
      for (final id in BlueprintId.values) SpriteNames.building(id),
      SpriteNames.stump,
      SpriteNames.sapling,
      SpriteNames.rock,
      for (final kind in ToolKind.values) SpriteNames.item(kind),
      for (final kind in TreeKind.values) SpriteNames.tree(kind),
      for (final kind in DecorationKind.values) SpriteNames.decoration(kind),
    ];

    // when
    final frames = LpcAtlas.parse(source);

    // then
    expect(frames.keys, containsAll(expected));
  });

  test('testWhenParsingTheGeneratedAtlasThenTheStumpSaplingAndRockHaveTheirSizes', () {
    // given
    final source = File('lib/core/assets/images/lpc/forest.json').readAsStringSync();

    // when
    final frames = LpcAtlas.parse(source);

    // then
    final sizes = [
      for (final name in [SpriteNames.stump, SpriteNames.sapling, SpriteNames.rock])
        (frames[name]!.width, frames[name]!.height),
    ];
    expect(sizes, [(50, 41), (18, 30), (61, 45)]);
  });

  test('testWhenParsingTheGeneratedAtlasThenTheVillageBuildingsHaveTheirFrames', () {
    // given
    final source = File('lib/core/assets/images/lpc/forest.json').readAsStringSync();
    const ids = BlueprintId.values;

    // when
    final frames = LpcAtlas.parse(source);

    // then
    expect(ids.where((id) => !frames.containsKey(SpriteNames.building(id))), isEmpty);
    expect(frames.containsKey('camp'), isFalse);
  });
}
