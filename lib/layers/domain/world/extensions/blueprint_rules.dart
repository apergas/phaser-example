import '../../entities/building/blueprint_entity.dart';

extension BlueprintRules on BlueprintEntity {
  bool isAffordableWith(int wood) => wood >= woodCost;
}
