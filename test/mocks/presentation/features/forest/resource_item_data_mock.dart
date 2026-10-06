import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/presentation/features/forest/models/resource_item_data.dart';

abstract final class ResourceItemDataMock {
  static ResourceItemData wood(int amount) => ResourceItemData(
    resource: Resource.wood,
    name: Internationalize.forestResource(resource: Resource.wood),
    amount: amount,
  );
}
