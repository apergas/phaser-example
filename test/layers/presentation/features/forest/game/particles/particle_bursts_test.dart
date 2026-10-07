import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/forest/particle_kind.dart';
import 'package:rpg/layers/presentation/features/forest/game/particles/particle_bursts.dart';

import '../../../../../../mocks/presentation/features/forest/game/particle_mock.dart';

double _angleDegrees(double x, double y) {
  final degrees = math.atan2(y, x) * 180 / math.pi;
  return degrees < 0 ? degrees + 360 : degrees;
}

void main() {
  test('testWhenTheAxeHitsFromTheLeftThenEightChipsFlyUpAndLeft', () {
    // given
    final random = ParticleMock.chipsRandom;

    // when
    final chips = ParticleBursts.woodChips(trunkBase: ParticleMock.trunkBase, playerOnLeft: true, random: random);

    // then
    expect(chips, hasLength(8));
    for (final chip in chips) {
      final speed = math.sqrt(chip.velocityX * chip.velocityX + chip.velocityY * chip.velocityY);
      expect(chip.kind, ParticleKind.woodChip);
      expect(chip.origin, ParticleMock.chipOrigin);
      expect(speed, inInclusiveRange(30, 80));
      expect(_angleDegrees(chip.velocityX, chip.velocityY), inInclusiveRange(200, 290));
      expect(chip.gravity, 220);
      expect(chip.lifespanSeconds, 0.5);
    }
  });

  test('testWhenTheAxeHitsFromTheRightThenChipsFlyUpAndRight', () {
    // given
    final random = ParticleMock.chipsRandom;

    // when
    final chips = ParticleBursts.woodChips(trunkBase: ParticleMock.trunkBase, playerOnLeft: false, random: random);

    // then
    for (final chip in chips) {
      expect(_angleDegrees(chip.velocityX, chip.velocityY), inInclusiveRange(250, 340));
    }
  });

  test('testWhenHammeringThenSixDustPuffsRiseFromTheFrontWall', () {
    // given
    const front = ParticleMock.buildingFront;

    // when
    final dust = ParticleBursts.dust(front: front, random: ParticleMock.dustRandom);

    // then
    expect(dust, hasLength(6));
    expect(dust.first.origin, ParticleMock.dustOrigin);
    expect(dust.first.lifespanSeconds, 0.45);
    expect(ParticleBursts.dustSortY(front), 205);
    expect(ParticleBursts.chipsSortY(ParticleMock.trunkBase), 121);
  });

  test('testWhenAParticleAgesThenFollowsAClosedFormTrajectory', () {
    // given
    final chip = ParticleBursts.woodChips(
      trunkBase: ParticleMock.trunkBase,
      playerOnLeft: true,
      random: ParticleMock.seededOne,
    ).first;

    // when
    final position = chip.position(0.2);

    // then
    expect(position.x, closeTo(100 + chip.velocityX * 0.2, 1e-9));
    expect(position.y, closeTo(110 + chip.velocityY * 0.2 + 0.5 * 220 * 0.04, 1e-9));
    expect(chip.alpha(0.25), closeTo(0.5, 1e-9));
    expect(chip.isAlive(0.49), isTrue);
    expect(chip.isAlive(0.5), isFalse);
  });

  test('testWhenGearIsBoughtThenTenSparklesRiseAroundTheHerosChest', () {
    // given
    const feet = ParticleMock.heroFeet;

    // when
    final sparkles = ParticleBursts.sparkles(feet: feet, random: ParticleMock.sparklesRandom);

    // then
    expect(sparkles, hasLength(10));
    for (final sparkle in sparkles) {
      expect(sparkle.kind, ParticleKind.sparkle);
      expect(sparkle.origin.y, 126);
      expect(sparkle.origin.x, inInclusiveRange(140, 160));
      expect(_angleDegrees(sparkle.velocityX, sparkle.velocityY), inInclusiveRange(200, 340));
      expect(sparkle.gravity, 0);
      expect(sparkle.lifespanSeconds, 0.6);
    }
    expect(ParticleBursts.sparklesSortY(feet), 151);
  });
}
