import '../../../../core/config/constants/enum/fight_advice.dart';
import 'fight_log_entity.dart';

sealed class FightResultEntity {
  const FightResultEntity();
}

final class FightPlayedEntity extends FightResultEntity {
  final FightLogEntity log;
  final FightAdvice? advice;

  const FightPlayedEntity({required this.log, this.advice});

  @override
  bool operator ==(Object other) => other is FightPlayedEntity && other.log == log && other.advice == advice;

  @override
  int get hashCode => Object.hash(FightPlayedEntity, log, advice);
}

final class FightLockedEntity extends FightResultEntity {
  const FightLockedEntity();

  @override
  bool operator ==(Object other) => other is FightLockedEntity;

  @override
  int get hashCode => (FightLockedEntity).hashCode;
}
