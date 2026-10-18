import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';

class StockEntity {
  final Map<Resource, int> resources;

  const StockEntity({this.resources = const {}});

  StockEntity copyWith({Map<Resource, int>? resources}) => StockEntity(resources: resources ?? this.resources);

  @override
  bool operator ==(Object other) =>
      other is StockEntity && const MapEquality<Resource, int>().equals(other.resources, resources);

  @override
  int get hashCode => const MapEquality<Resource, int>().hash(resources);
}
