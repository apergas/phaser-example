import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/forest/quest_item_status.dart';
import 'package:rpg/layers/presentation/features/forest/models/build_item_data.dart';
import 'package:rpg/layers/presentation/features/forest/models/hud_data.dart';
import 'package:rpg/layers/presentation/features/forest/models/quest_item_data.dart';

import 'build_item_data_mock.dart';
import 'quest_item_data_mock.dart';

abstract final class HudDataMock {
  static HudData get mock => _make(wood: 0);

  static HudData get mockCopy => _make(wood: 0);

  static HudData get withWood => _make(wood: 6);

  static HudData get start => HudData(
    wood: 0,
    hasAxe: false,
    questBadge: '0/3',
    quests: [QuestItemDataMock.current, QuestItemDataMock.pending],
    buildItems: [BuildItemDataMock.unaffordable],
    isBuildLocked: false,
  );

  static HudData get gathering => HudData(
    wood: 23,
    hasAxe: true,
    questBadge: '1/3',
    quests: QuestItemDataMock.all,
    buildItems: [BuildItemDataMock.affordable],
    isBuildLocked: false,
  );

  static HudData get placing => HudData(
    wood: 23,
    hasAxe: true,
    questBadge: '1/3',
    quests: QuestItemDataMock.all,
    buildItems: [BuildItemDataMock.affordable],
    isBuildLocked: true,
  );

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
