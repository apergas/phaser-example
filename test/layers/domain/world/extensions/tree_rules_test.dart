import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/world/extensions/tree_rules.dart';

import '../../../../mocks/domain/entities/tree/tree_entity_mock.dart';

void main() {
  test('testWhenHitTheRequiredTimesThenTreeIsFelledAndIgnoresMoreHits', () {
    // given
    var tree = TreeEntityMock.mock;

    // when
    for (var i = 0; i < 5; i++) {
      tree = tree.hit();
    }
    final hitAgain = tree.hit();

    // then
    expect(tree.isFelled, isTrue);
    expect(hitAgain.hitsRemaining, 0);
  });

  test('testWhenHitOnceThenOriginalTreeIsUnchanged', () {
    // given
    const tree = TreeEntityMock.mock;

    // when
    final hitTree = tree.hit();

    // then
    expect(tree.hitsRemaining, 5);
    expect(hitTree.hitsRemaining, 4);
  });
}
