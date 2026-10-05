import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/forest/facing.dart';
import 'package:rpg/core/config/constants/enum/forest/player_sheet.dart';
import 'package:rpg/core/config/constants/enum/forest/work_tool.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/player_frame.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/player_frames.dart';

import '../../../../../../mocks/presentation/features/forest/player_pose_mock.dart';
import '../../../../../../mocks/presentation/features/forest/player_render_data_mock.dart';

void main() {
  test('testWhenChoosingTheRowThenFollowsUpLeftDownRight', () {
    // given
    const facings = [Facing.up, Facing.left, Facing.down, Facing.right];

    // when
    final rows = facings.map(PlayerFrames.row).toList();

    // then
    expect(rows, [0, 1, 2, 3]);
  });

  test('testWhenWalkingThenCyclesColumnsOneToEightAtTenFps', () {
    // given
    const times = [0.0, 0.1, 0.79, 0.8];

    // when
    final columns = times.map(PlayerFrames.walkColumn).toList();

    // then
    expect(columns, [1, 2, 8, 1]);
  });

  test('testWhenIdleThenAlternatesTwoColumnsAtTwoFps', () {
    // given
    const times = [0.0, 0.49, 0.5, 1.0];

    // when
    final columns = times.map(PlayerFrames.idleColumn).toList();

    // then
    expect(columns, [0, 0, 1, 0]);
  });

  test('testWhenWorkingThenTheSwingProgressPicksTheSequenceStep', () {
    // given
    const progress = [0.0, 0.3, 0.99, 1.0];

    // when
    final chop = progress.map((value) => PlayerFrames.workColumn(WorkTool.axe, value)).toList();
    final hammer = progress.map((value) => PlayerFrames.workColumn(WorkTool.hammer, value)).toList();

    // then
    expect(chop, [0, 5, 1, 1]);
    expect(hammer, [0, 5, 1, 1]);
  });

  test('testWhenBuildingTheFrameThenUsesTheSheetOfThePose', () {
    // given
    final chopping = PlayerRenderDataMock.chopping;
    final walking = PlayerRenderDataMock.walkingWithAxe;

    // when
    final workFrame = PlayerFrames.frame(chopping, 0);
    final walkFrame = PlayerFrames.frame(walking, 0.1);

    // then
    expect(workFrame, const PlayerFrame(sheet: PlayerSheet.chop, column: 5, row: 1, cellSize: 128, anchorY: 94 / 128));
    expect(walkFrame, const PlayerFrame(sheet: PlayerSheet.walkAxe, column: 2, row: 3, cellSize: 64, anchorY: 62 / 64));
    expect(PlayerFrames.animationKey(walking), 'walkAxe-right');
    expect(PlayerFrames.sheet(PlayerPoseMock.idleWithoutAxe), PlayerSheet.idle);
  });
}
