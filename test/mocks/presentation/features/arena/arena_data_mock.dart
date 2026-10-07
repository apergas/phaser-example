import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/layers/presentation/features/arena/bloc/arena_bloc.dart';

import 'arena_effect_mock.dart';
import 'arena_level_item_data_mock.dart';
import 'arena_result_data_mock.dart';
import 'fight_replay_data_mock.dart';
import 'fighter_render_data_mock.dart';

abstract final class ArenaDataMock {
  static ArenaData get preview => ArenaData(
    levels: [ArenaLevelItemDataMock.rookieOpen, ArenaLevelItemDataMock.veteranLocked],
    selected: ArenaLevelId.banditRookie,
    heroPower: 31,
    fighters: const [FighterRenderDataMock.heroIdle, FighterRenderDataMock.rookieBanditIdle],
  );

  static ArenaData get heroAlone => preview.copyWith(fighters: const [FighterRenderDataMock.heroIdle]);

  static ArenaData get replaying => preview.copyWith(replay: FightReplayDataMock.victoryOverBanditStart);

  static ArenaData get banditHit => replaying.copyWith(
    fighters: const [FighterRenderDataMock.heroIdle, FighterRenderDataMock.rookieBanditHurt],
    effects: const [ArenaEffectMock.banditHitForFour],
  );

  static ArenaData get heroDodged => replaying.copyWith(effects: const [ArenaEffectMock.heroDodged]);

  static ArenaData get heroGotASecondWind => replaying.copyWith(
    effects: const [ArenaEffectMock.heroHealedTwelve, ArenaEffectMock.secondWindUsed],
  );

  static ArenaData get won => preview.copyWith(
    replay: () => FightReplayDataMock.victoryOverBanditStart().skipped(),
    fighters: const [FighterRenderDataMock.heroAfterBeatingTheRookie, FighterRenderDataMock.rookieBanditDown],
    result: () => ArenaResultDataMock.victoryTenGold,
    effects: const [ArenaEffectMock.won],
  );
}
