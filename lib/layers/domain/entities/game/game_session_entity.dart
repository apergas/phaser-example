import '../../quests/quest_log.dart';
import '../../world/world.dart';

class GameSessionEntity {
  final World world;
  final QuestLog quests;

  const GameSessionEntity({required this.world, required this.quests});

  @override
  bool operator ==(Object other) =>
      other is GameSessionEntity && identical(other.world, world) && identical(other.quests, quests);

  @override
  int get hashCode => Object.hash(identityHashCode(world), identityHashCode(quests));
}
