sealed class IntentEntity {
  const IntentEntity();
}

final class ChopIntentEntity extends IntentEntity {
  final String treeId;

  const ChopIntentEntity({required this.treeId});

  @override
  bool operator ==(Object other) => other is ChopIntentEntity && other.treeId == treeId;

  @override
  int get hashCode => Object.hash(ChopIntentEntity, treeId);
}

final class ConstructIntentEntity extends IntentEntity {
  final String buildingId;

  const ConstructIntentEntity({required this.buildingId});

  @override
  bool operator ==(Object other) => other is ConstructIntentEntity && other.buildingId == buildingId;

  @override
  int get hashCode => Object.hash(ConstructIntentEntity, buildingId);
}
