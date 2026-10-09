import '../../../../core/config/constants/enum/fight_advice.dart';
import 'fight_log_entity.dart';

sealed class FightResultEntity {
  const FightResultEntity();
}

final class FightPlayedEntity extends FightResultEntity {
  final FightLogEntity log;
  final FightAdvice? advice;
  final bool isFirstChampionship;

  const FightPlayedEntity({required this.log, this.advice, this.isFirstChampionship = false});

  @override
  bool operator ==(Object other) =>
      other is FightPlayedEntity &&
      other.log == log &&
      other.advice == advice &&
      other.isFirstChampionship == isFirstChampionship;

  @override
  int get hashCode => Object.hash(FightPlayedEntity, log, advice, isFirstChampionship);
}

final class FightLockedEntity extends FightResultEntity {
  const FightLockedEntity();

  @override
  bool operator ==(Object other) => other is FightLockedEntity;

  @override
  int get hashCode => (FightLockedEntity).hashCode;
}
