import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/forest/quest_item_status.dart';
import 'package:rpg/layers/presentation/features/forest/models/build_item_data.dart';
import 'package:rpg/layers/presentation/features/forest/models/hud_data.dart';
import 'package:rpg/layers/presentation/features/forest/models/quest_item_data.dart';

abstract final class HudDataMock {
  static HudData get mock => _make(wood: 0);

  static HudData get mockCopy => _make(wood: 0);

  static HudData get withWood => _make(wood: 6);

  static HudData _make({required int wood}) {
    return HudData(
      wood: wood,
      hasAxe: false,
      questBadge: '0/3',
      quests: [QuestItemData(title: 'Recoge el hacha', progressText: '', status: QuestItemStatus.current)],
      buildItems: [
        BuildItemData(
          blueprint: BlueprintId.house,
          name: 'Casa',
          costText: '15 de madera',
          missingText: 'Faltan 15',
          isEnabled: false,
        ),
      ],
      isBuildLocked: false,
    );
  }
}
