import 'package:farming/core/config/constants/enum/resource.dart';

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

  static const Map<Resource, int> doubleStrikePrice = {Resource.gold: 60, Resource.mana: 20};

  static const Map<Resource, int> tenGoldShortOfDoubleStrike = {Resource.gold: 50, Resource.mana: 20};

  static const Map<Resource, int> doubleStrikeGoldWithoutMana = {Resource.gold: 60};

  static const Map<Resource, int> banditTrioReward = {Resource.gold: 75, Resource.mana: 20};

  static const Map<Resource, int> banditTrioRepeatReward = {Resource.gold: 25, Resource.mana: 6};

  static const Map<Resource, int> barbarianChiefReward = {Resource.gold: 150, Resource.mana: 50};

  static const Map<Resource, int> barbarianChiefRepeatReward = {Resource.gold: 50, Resource.mana: 16};

  static const Map<Resource, int> thirtyGold = {Resource.gold: 30};

  static const Map<Resource, int> tenGoldAndZeroMana = {Resource.gold: 10, Resource.mana: 0};

  static const Map<Resource, int> sixManaBeforeTwentyFiveGold = {Resource.mana: 6, Resource.gold: 25};

  static const Map<Resource, int> doubleStrikeLevelTwoPrice = {Resource.gold: 90, Resource.mana: 30};

  static const Map<Resource, int> doubleStrikeLevelThreePrice = {Resource.gold: 135, Resource.mana: 45};
}
