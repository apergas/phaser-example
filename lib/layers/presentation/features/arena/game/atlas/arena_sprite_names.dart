import '../../../../../../core/config/constants/enum/enemy_kind.dart';
import '../../../../../../core/config/constants/enum/gear_id.dart';

abstract final class ArenaSpriteNames {
  static const String hero = 'hero';
  static const String fence = 'arena-fence';

  static String enemy(EnemyKind kind) => switch (kind) {
    EnemyKind.bandit => 'bandit',
    EnemyKind.barbarian => 'barbarian',
    EnemyKind.barbarianChief => 'barbarian-chief',
    EnemyKind.wolf => 'wolf',
    EnemyKind.bear => 'bear',
    EnemyKind.banditVeteran => 'bandit-veteran',
  };

  static String heroWith(GearId? weapon, GearId? armor) => '$hero${_weaponSuffix(weapon)}${_armorSuffix(armor)}';

  static String fighter(EnemyKind? kind, {GearId? weapon, GearId? armor}) =>
      kind == null ? heroWith(weapon, armor) : enemy(kind);

  static String idle(String fighter, int column) => '$fighter-idle-$column';

  static String walk(String fighter, int column) => '$fighter-walk-$column';

  static String slash(String fighter, int column) => '$fighter-slash-$column';

  static String attack(String fighter, int column) => '$fighter-attack-$column';

  static String down(String fighter) => '$fighter-down';

  static String _weaponSuffix(GearId? weapon) => switch (weapon) {
    GearId.shortSword => '-short-sword',
    GearId.ironSword => '-iron-sword',
    GearId.steelSword => '-steel-sword',
    null ||
    GearId.woodcutterAxe ||
    GearId.workClothes ||
    GearId.leatherArmor ||
    GearId.chainMail ||
    GearId.plateArmor => '',
  };

  static String _armorSuffix(GearId? armor) => switch (armor) {
    GearId.leatherArmor => '-leather',
    GearId.chainMail => '-chain-mail',
    GearId.plateArmor => '-plate',
    null ||
    GearId.woodcutterAxe ||
    GearId.shortSword ||
    GearId.ironSword ||
    GearId.steelSword ||
    GearId.workClothes => '',
  };
}
