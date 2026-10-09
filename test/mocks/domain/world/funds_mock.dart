import 'package:rpg/core/config/constants/enum/resource.dart';

abstract final class FundsMock {
  static const Map<Resource, int> tenGold = {Resource.gold: 10};

  static const Map<Resource, int> fourGold = {Resource.gold: 4};

  static const Map<Resource, int> twentyGold = {Resource.gold: 20};

  static const Map<Resource, int> fiveWoodAndFourGold = {Resource.wood: 5, Resource.gold: 4};

  static const Map<Resource, int> zeroGold = {Resource.gold: 0};

  static const Map<Resource, int> minusThreeGold = {Resource.gold: -3};

  static const Map<Resource, int> threeGold = {Resource.gold: 3};

  static const Map<Resource, int> shortSwordPrice = {Resource.gold: 30};

  static const Map<Resource, int> fiveGoldShortOfShortSword = {Resource.gold: 25};

  static const Map<Resource, int> doubleStrikePrice = {Resource.gold: 60};

  static const Map<Resource, int> tenGoldShortOfDoubleStrike = {Resource.gold: 50};
}
