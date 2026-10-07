import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/presentation/features/forest/models/resource_item_data.dart';

abstract final class ResourceItemDataMock {
  static ResourceItemData wood(int amount) => ResourceItemData(
    resource: Resource.wood,
    name: Internationalize.forestResource(resource: Resource.wood),
    amount: amount,
  );

  static ResourceItemData gold(int amount) => ResourceItemData(
    resource: Resource.gold,
    name: Internationalize.forestResource(resource: Resource.gold),
    amount: amount,
  );

  static ResourceItemData of(Resource resource, int amount) => ResourceItemData(
    resource: resource,
    name: Internationalize.forestResource(resource: resource),
    amount: amount,
  );
}
