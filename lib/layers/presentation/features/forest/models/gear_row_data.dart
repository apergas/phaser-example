import '../../../../../core/config/constants/enum/gear_slot.dart';
import 'gear_item_data.dart';

class GearRowData {
  final GearSlot slot;
  final String title;
  final GearItemData equipped;
  final GearItemData? next;

  const GearRowData({required this.slot, required this.title, required this.equipped, this.next});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GearRowData &&
          other.slot == slot &&
          other.title == title &&
          other.equipped == equipped &&
          other.next == next;

  @override
  int get hashCode => Object.hash(slot, title, equipped, next);

  @override
  String toString() => 'GearRowData($slot, $title, equipped: $equipped, next: $next)';
}
