import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/sprite_names.dart';

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
}
