import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/particles/particle_burst_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/particles/particle_bursts.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/forest/game/particle_mock.dart';

void main() {
  testWithFlameGame('testWhenEveryParticleFadesThenTheBurstRemovesItself', (game) async {
    // given
    final burst = ParticleBurstComponent(
      particles: ParticleBursts.woodChips(
        trunkBase: ParticleMock.trunkBase,
        playerOnLeft: true,
        random: ParticleMock.seededOne,
      ),
      sortY: ParticleBursts.chipsSortY(ParticleMock.trunkBase),
    );
    await game.ensureAdd(burst);

    // when
    game.update(0.3);
    final aliveHalfway = burst.aliveCount;
    game.update(0.25);
    await game.ready();

    // then
    expect(burst.priority, RenderDepth.bySortY(121) + 1);
    expect(aliveHalfway, 8);
    expect(burst.isMounted, isFalse);
  });
}
