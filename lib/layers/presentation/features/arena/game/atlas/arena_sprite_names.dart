import '../../../../../../core/config/constants/enum/enemy_kind.dart';
import '../../../../../../core/config/constants/enum/gear_id.dart';

abstract final class ArenaSpriteNames {
  static const String hero = 'hero';
  static const String grass = 'arena-grass';
  static const String fence = 'arena-fence';

  static String enemy(EnemyKind kind) => switch (kind) {
    EnemyKind.bandit => 'bandit',
    EnemyKind.barbarian => 'barbarian',
    EnemyKind.barbarianChief => 'barbarian-chief',
    EnemyKind.wolf => 'wolf',
    EnemyKind.bear => 'bear',
    EnemyKind.banditVeteran => 'bandit-veteran',
  };

  static String heroWith(GearId? weapon) => switch (weapon) {
    GearId.shortSword => 'hero-short-sword',
    GearId.ironSword => 'hero-iron-sword',
    GearId.steelSword => 'hero-steel-sword',
    null ||
    GearId.woodcutterAxe ||
    GearId.workClothes ||
    GearId.leatherArmor ||
    GearId.chainMail ||
    GearId.plateArmor => hero,
  };

  static String fighter(EnemyKind? kind, {GearId? weapon}) => kind == null ? heroWith(weapon) : enemy(kind);

  static String idle(String fighter, int column) => '$fighter-idle-$column';

  static String walk(String fighter, int column) => '$fighter-walk-$column';

  static String slash(String fighter, int column) => '$fighter-slash-$column';

  static String attack(String fighter, int column) => '$fighter-attack-$column';

  static String down(String fighter) => '$fighter-down';
}
