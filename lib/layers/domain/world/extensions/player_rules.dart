import '../../entities/geometry/position_entity.dart';
import '../../entities/player/activity_entity.dart';
import '../../entities/player/intent_entity.dart';
import '../../entities/player/inventory_entity.dart';
import '../../entities/player/player_entity.dart';
import 'position_geometry.dart';

extension PlayerRules on PlayerEntity {
  PlayerEntity walkTo(PositionEntity destination, {IntentEntity? intent}) {
    return copyWith(
      activity: WalkingActivityEntity(destination: destination, intent: intent),
    );
  }

  PlayerEntity startWork(IntentEntity intent) {
    return copyWith(activity: WorkingActivityEntity(intent: intent, elapsedMs: 0));
  }

  PlayerEntity continueWork(double elapsedMs) {
    final working = activity;
    if (working is! WorkingActivityEntity) return this;
    return copyWith(activity: working.copyWith(elapsedMs: elapsedMs));
  }

  PlayerEntity stop() => copyWith(activity: const IdleActivityEntity());

  PositionEntity? nextPosition(double deltaMs) {
    final walking = activity;
    if (walking is! WalkingActivityEntity) return null;
    return position.moveTowards(walking.destination, speed * deltaMs / 1000);
  }

  PlayerEntity placeAt(PositionEntity position) => copyWith(position: position);

  PlayerEntity withInventory(InventoryEntity inventory) => copyWith(inventory: inventory);
}
