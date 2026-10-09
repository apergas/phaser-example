import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/sprite_names.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_constants.dart';

void main() {
  test('testWhenNamingSpritesThenFollowsTheAtlasFrameNames', () {
    // given
    const tree = TreeKind.broad;
    const decoration = DecorationKind.tallGrass;

    // when
    final treeName = SpriteNames.tree(tree);
    final decorationName = SpriteNames.decoration(decoration);

    // then
    expect(treeName, 'tree-broad');
    expect(decorationName, 'decor-tall-grass');
  });

  test('testWhenNamingBuildingsAndItemsThenFollowsTheAtlasFrameNames', () {
    // given
    const house = BlueprintId.house;
    const axe = ToolKind.axe;

    // when
    final buildingName = SpriteNames.building(house);
    final frontOffset = RenderConstants.buildingFrontOffset(house);
    final itemName = SpriteNames.item(axe);

    // then
    expect(buildingName, 'house');
    expect(frontOffset, 24);
    expect(itemName, 'axe-pickup');
  });

  test('testWhenNamingTheWorkshopsThenUsesTheirFramesAndTheHouseFrontOffset', () {
    // given
    const forge = BlueprintId.forge;
    const armory = BlueprintId.armory;

    // when
    final names = (SpriteNames.building(forge), SpriteNames.building(armory));
    final offsets = (RenderConstants.buildingFrontOffset(forge), RenderConstants.buildingFrontOffset(armory));

    // then
    expect(names, ('forge', 'armory'));
    expect(offsets, (24, 24));
  });

  test('testWhenNamingTheMageTowerThenUsesItsFrameAndTheHouseFrontOffset', () {
    // given
    const id = BlueprintId.mageTower;

    // when
    final name = SpriteNames.building(id);
    final offset = RenderConstants.buildingFrontOffset(id);

    // then
    expect(name, 'mage-tower');
    expect(offset, 24);
  });
}
