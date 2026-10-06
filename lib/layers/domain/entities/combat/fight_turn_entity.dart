import '../../../../core/config/constants/enum/fight_action.dart';
import '../../../../core/config/constants/enum/fight_side.dart';

class FightTurnEntity {
  final int round;
  final FightSide actor;
  final int actorIndex;
  final FightSide target;
  final int targetIndex;
  final FightAction action;
  final int damage;
  final int targetHealthAfter;

  const FightTurnEntity({
    required this.round,
    required this.actor,
    required this.actorIndex,
    required this.target,
    required this.targetIndex,
    required this.action,
    required this.damage,
    required this.targetHealthAfter,
  }) : assert(damage >= 0),
       assert(targetHealthAfter >= 0);

  FightTurnEntity copyWith({
    int? round,
    FightSide? actor,
    int? actorIndex,
    FightSide? target,
    int? targetIndex,
    FightAction? action,
    int? damage,
    int? targetHealthAfter,
  }) {
    return FightTurnEntity(
      round: round ?? this.round,
      actor: actor ?? this.actor,
      actorIndex: actorIndex ?? this.actorIndex,
      target: target ?? this.target,
      targetIndex: targetIndex ?? this.targetIndex,
      action: action ?? this.action,
      damage: damage ?? this.damage,
      targetHealthAfter: targetHealthAfter ?? this.targetHealthAfter,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FightTurnEntity &&
      other.round == round &&
      other.actor == actor &&
      other.actorIndex == actorIndex &&
      other.target == target &&
      other.targetIndex == targetIndex &&
      other.action == action &&
      other.damage == damage &&
      other.targetHealthAfter == targetHealthAfter;

  @override
  int get hashCode => Object.hash(round, actor, actorIndex, target, targetIndex, action, damage, targetHealthAfter);

  @override
  String toString() =>
      'FightTurnEntity(round: $round, ${actor.name}[$actorIndex] ${action.name} ${target.name}[$targetIndex], '
      'damage: $damage, targetHealthAfter: $targetHealthAfter)';
}
