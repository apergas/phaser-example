import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

void main() {
  test('testWhenSortingByBaseThenLowerOnScreenIsDrawnInFront', () {
    // given
    const behind = 120.0;
    const front = 120.5;

    // when
    final behindPriority = RenderDepth.bySortY(behind);
    final frontPriority = RenderDepth.bySortY(front);

    // then
    expect(behindPriority, 12000);
    expect(frontPriority, 12050);
    expect(RenderDepth.ground < RenderDepth.shadow, isTrue);
    expect(RenderDepth.shadow < RenderDepth.bySortY(0), isTrue);
    expect(RenderDepth.overlay > RenderDepth.bySortY(100000), isTrue);
  });
}
