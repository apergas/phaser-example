import 'package:rpg/layers/domain/entities/player/intent_entity.dart';

abstract final class IntentEntityMock {
  static const ChopIntentEntity chop = ChopIntentEntity(treeId: 'tree-1');

  static const ConstructIntentEntity construct = ConstructIntentEntity(buildingId: 'building-1');

  static ChopIntentEntity makeChop({String treeId = 'tree-1'}) => ChopIntentEntity(treeId: treeId);

  static ConstructIntentEntity makeConstruct({String buildingId = 'building-1'}) =>
      ConstructIntentEntity(buildingId: buildingId);
}
