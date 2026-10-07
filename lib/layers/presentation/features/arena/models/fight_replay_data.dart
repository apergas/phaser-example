import 'dart:math' as math;

import '../../../../../core/config/constants/enum/fight_side.dart';
import '../../../../domain/entities/combat/fight_log_entity.dart';
import '../game/render/arena_render_constants.dart';

class FightReplayData {
  static const int noTurn = -1;

  final FightLogEntity log;
  final double elapsedMs;
  final int turnIndex;

  const FightReplayData({required this.log, required this.elapsedMs, required this.turnIndex});

  factory FightReplayData.start(FightLogEntity log) => FightReplayData(log: log, elapsedMs: 0, turnIndex: noTurn);

  double get durationMs => ArenaRenderConstants.leadInMs + log.turns.length * ArenaRenderConstants.turnMs;

  bool get isFinished => elapsedMs >= durationMs;

  int? get swingingTurn {
    final sinceFirstTurn = elapsedMs - ArenaRenderConstants.leadInMs;
    if (isFinished || sinceFirstTurn < 0) return null;
    return sinceFirstTurn ~/ ArenaRenderConstants.turnMs;
  }

  double get swingProgress {
    final sinceFirstTurn = elapsedMs - ArenaRenderConstants.leadInMs;
    if (isFinished || sinceFirstTurn < 0) return 0;
    return (sinceFirstTurn % ArenaRenderConstants.turnMs) / ArenaRenderConstants.turnMs;
  }

  FightReplayData advanced(double deltaMs) {
    final elapsed = math.min(durationMs, elapsedMs + deltaMs);
    return FightReplayData(log: log, elapsedMs: elapsed, turnIndex: _lastImpactAt(elapsed));
  }

  FightReplayData skipped() => advanced(durationMs);

  int maxHealthOf(FightSide side, int index) {
    return switch (side) {
      FightSide.hero => log.heroStats.health,
      FightSide.enemy => log.enemies[index].stats.health,
    };
  }

  int healthOf(FightSide side, int index) => healthBefore(turnIndex + 1, side, index);

  int healthBefore(int turn, FightSide side, int index) {
    var health = maxHealthOf(side, index);
    for (final played in log.turns.take(turn)) {
      if (played.target == side && played.targetIndex == index) health = played.targetHealthAfter;
    }
    return health;
  }

  int _lastImpactAt(double elapsedMs) {
    final firstImpactMs =
        ArenaRenderConstants.leadInMs + ArenaRenderConstants.impactShare * ArenaRenderConstants.turnMs;
    if (elapsedMs < firstImpactMs) return noTurn;
    return math.min(log.turns.length - 1, (elapsedMs - firstImpactMs) ~/ ArenaRenderConstants.turnMs);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FightReplayData && other.log == log && other.elapsedMs == elapsedMs && other.turnIndex == turnIndex;

  @override
  int get hashCode => Object.hash(log, elapsedMs, turnIndex);
}
