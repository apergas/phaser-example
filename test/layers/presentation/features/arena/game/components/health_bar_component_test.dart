import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/arena/game/components/health_bar_component.dart';
import 'package:rpg/layers/presentation/theme/colors/custom_colors.dart';

void main() {
  testWithFlameGame('testWhenHealthDropsThenTheBarEasesDownToTheNewValue', (game) async {
    // given
    final bar = HealthBarComponent(position: Vector2(100, 100));
    await game.ensureAdd(bar);

    // when
    bar.show(health: 10, maxHealth: 20);
    final atStart = bar.displayedFraction;
    game.update(0.15);
    final halfway = bar.displayedFraction;
    game.update(0.2);

    // then
    expect(atStart, 1);
    expect(halfway, closeTo(1 - 0.5 * 0.7071, 0.001));
    expect(bar.displayedFraction, 0.5);
    expect(bar.fillColor, CustomColors.warning);
  });

  testWithFlameGame('testWhenSnappedThenTheBarJumpsToTheTargetAndTurnsRedWhenLow', (game) async {
    // given
    final bar = HealthBarComponent(position: Vector2(100, 100));
    await game.ensureAdd(bar);
    bar.show(health: 2, maxHealth: 20);

    // when
    bar.snap();

    // then
    expect(bar.displayedFraction, closeTo(0.1, 1e-9));
    expect(bar.fillColor, CustomColors.error);
  });
}
