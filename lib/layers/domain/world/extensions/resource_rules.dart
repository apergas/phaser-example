import '../../../../core/config/constants/enum/resource.dart';

extension ResourceRules on Resource {
  bool get takesCargo => switch (this) {
    Resource.wood => true,
    Resource.gold => false,
    Resource.mana => false,
    Resource.stone => true,
  };
}
