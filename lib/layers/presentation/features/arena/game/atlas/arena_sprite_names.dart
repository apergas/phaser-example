import '../../../../../../core/config/constants/enum/enemy_kind.dart';

abstract final class ArenaSpriteNames {
  static const String hero = 'hero';
  static const String grass = 'arena-grass';
  static const String fence = 'arena-fence';

  static String enemy(EnemyKind kind) => switch (kind) {
    EnemyKind.bandit => 'bandit',
    EnemyKind.barbarian => 'barbarian',
    EnemyKind.barbarianChief => 'barbarian',
    EnemyKind.wolf => 'wolf',
    EnemyKind.bear => 'bear',
  };

  static String fighter(EnemyKind? kind) => kind == null ? hero : enemy(kind);

  static String idle(String fighter, int column) => '$fighter-idle-$column';

  static String slash(String fighter, int column) => '$fighter-slash-$column';

  static String attack(String fighter, int column) => '$fighter-attack-$column';

  static String down(String fighter) => '$fighter-down';
}
