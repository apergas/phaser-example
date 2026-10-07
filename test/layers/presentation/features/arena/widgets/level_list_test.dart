import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/level_list.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/level_tile.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/arena/arena_level_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenATileIsTappedThenItsLevelIsSelected', (tester) async {
    // given
    final selected = <ArenaLevelId>[];
    final levels = [ArenaLevelItemDataMock.rookieCleared, ArenaLevelItemDataMock.veteranOpen];
    await tester.pumpHud(
      LevelList(levels: levels, selected: ArenaLevelId.banditRookie, isEnabled: true, onSelected: selected.add),
    );

    // when
    await tester.tap(find.text(levels[1].name));

    // then
    expect(selected, [ArenaLevelId.banditVeteran]);
    expect(tester.widgetList<LevelTile>(find.byType(LevelTile)).map((tile) => tile.isSelected), [true, false]);
  });

  testWidgets('testWhenTheListIsDisabledThenTapsAreIgnored', (tester) async {
    // given
    final selected = <ArenaLevelId>[];
    final levels = [ArenaLevelItemDataMock.rookieCleared, ArenaLevelItemDataMock.veteranOpen];
    await tester.pumpHud(
      LevelList(levels: levels, selected: ArenaLevelId.banditRookie, isEnabled: false, onSelected: selected.add),
    );

    // when
    await tester.tap(find.text(levels[1].name));

    // then
    expect(selected, isEmpty);
  });
}
