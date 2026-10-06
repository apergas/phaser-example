import '../../../../../core/config/constants/enum/resource.dart';

class ResourceItemData {
  final Resource resource;
  final String name;
  final int amount;

  const ResourceItemData({required this.resource, required this.name, required this.amount});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceItemData && other.resource == resource && other.name == name && other.amount == amount;

  @override
  int get hashCode => Object.hash(resource, name, amount);
}
