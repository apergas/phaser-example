import 'package:rpg/layers/presentation/features/forest/models/hud_data.dart';

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
      quests: [QuestItemDataMock.pickUpAxeCurrent],
      buildItems: [BuildItemDataMock.makeUnaffordable(missingWood: 15)],
      isBuildLocked: false,
    );
  }
}
