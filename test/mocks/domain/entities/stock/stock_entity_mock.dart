import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/layers/domain/entities/stock/stock_entity.dart';

abstract final class StockEntityMock {
  static const StockEntity mock = StockEntity();

  static const StockEntity withWood = StockEntity(resources: {Resource.wood: 6});

  static const StockEntity eightStone = StockEntity(resources: {Resource.stone: 8});

  static const Map<Resource, int> fortyWood = {Resource.wood: 40};

  static const StockEntity withStone = StockEntity(resources: {Resource.stone: 3});

  static const StockEntity withEveryResource = StockEntity(
    resources: {Resource.wood: 6, Resource.stone: 3, Resource.gold: 5, Resource.mana: 2},
  );

  static const Map<Resource, int> woodZeroStoneAndNegativeGold = {
    Resource.wood: 4,
    Resource.stone: 0,
    Resource.gold: -2,
  };

  static const Map<Resource, int> zeroWood = {Resource.wood: 0};

  static const Map<Resource, int> negativeWood = {Resource.wood: -1};

  static const Map<Resource, int> twoWood = {Resource.wood: 2};

  static const Map<Resource, int> fourWood = {Resource.wood: 4};

  static const Map<Resource, int> fiveWood = {Resource.wood: 5};

  static const Map<Resource, int> tenWood = {Resource.wood: 10};

  static const Map<Resource, int> fifteenWood = {Resource.wood: 15};

  static StockEntity make({int wood = 0, int stone = 0, int gold = 0, int mana = 0}) => StockEntity(
    resources: {
      if (wood > 0) Resource.wood: wood,
      if (stone > 0) Resource.stone: stone,
      if (gold > 0) Resource.gold: gold,
      if (mana > 0) Resource.mana: mana,
    },
  );
}
