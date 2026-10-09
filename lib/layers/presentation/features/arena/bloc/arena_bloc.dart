import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/arena/arena_level_item_status.dart';
import '../../../../../core/config/constants/enum/arena/fighter_pose.dart';
import '../../../../../core/config/constants/enum/arena/power_tone.dart';
import '../../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../../core/config/constants/enum/enemy_kind.dart';
import '../../../../../core/config/constants/enum/fight_action.dart';
import '../../../../../core/config/constants/enum/fight_advice.dart';
import '../../../../../core/config/constants/enum/fight_side.dart';
import '../../../../../core/config/constants/enum/gear_id.dart';
import '../../../../../core/config/constants/enum/gear_slot.dart';
import '../../../../../core/config/constants/enum/resource.dart';
import '../../../../../core/config/constants/enum/skill_id.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../../core/error-handling/exceptions/custom_exception.dart';
import '../../../../../core/services/navigation/source/navigation_service.dart';
import '../../../../domain/entities/combat/arena_entity.dart';
import '../../../../domain/entities/combat/arena_level_entity.dart';
import '../../../../domain/entities/combat/arena_level_status_entity.dart';
import '../../../../domain/entities/combat/fight_result_entity.dart';
import '../../../../domain/use-cases/arena/get_arena_use_case.dart';
import '../../../../domain/use-cases/arena/start_fight_use_case.dart';
import '../../../../domain/rules/gear.dart';
import '../../../../domain/use-cases/hero/get_hero_status_use_case.dart';
import '../game/render/arena_render_constants.dart';
import '../models/arena_effect.dart';
import '../models/arena_level_item_data.dart';
import '../models/arena_result_data.dart';
import '../models/fight_replay_data.dart';
import '../models/fighter_render_data.dart';

part 'arena_event.dart';
part 'arena_state.dart';

class ArenaBloc extends Bloc<ArenaEvent, ArenaState> {
  static const double evenPowerRatio = 1.25;

  final GetArenaUseCase _getArenaUseCase;
  final StartFightUseCase _startFightUseCase;
  final GetHeroStatusUseCase _getHeroStatusUseCase;
  final NavigationService _navigationService;

  ArenaEntity? _arena;
  FightAdvice? _advice;
  bool _isFirstChampionship = false;
  GearId _heroWeapon = GearId.woodcutterAxe;

  ArenaBloc({
    required this._getArenaUseCase,
    required this._startFightUseCase,
    required this._getHeroStatusUseCase,
    required this._navigationService,
  }) : super(const ArenaInitial()) {
    on<ArenaEvent>((event, emit) async {
      await switch (event) {
        ArenaStarted() => _onStarted(event, emit),
        ArenaLevelSelected() => _onLevelSelected(event, emit),
        ArenaFightRequested() => _onFightRequested(event, emit),
        ArenaReplayTicked() => _onReplayTicked(event, emit),
        ArenaReplaySkipped() => _onReplaySkipped(event, emit),
        ArenaClosed() => _onClosed(event, emit),
      };
    });
  }

  Future<void> _onStarted(ArenaStarted event, Emitter<ArenaState> emit) async {
    emit(ArenaInProgress(data: state.data.copyWith(effects: const [])));

    try {
      final arena = _getArenaUseCase();
      _arena = arena;
      _advice = null;
      final selected = _defaultSelection(arena);
      emit(
        ArenaSuccess(
          data: _withArena(const ArenaData(), arena).copyWith(
            selected: () => selected,
            fighters: _previewFighters(arena, selected),
          ),
        ),
      );
    } on AppException catch (exception) {
      _navigationService.showErrorPopUp(
        title: exception.title,
        message: exception.message,
        buttonTitle: Internationalize.commonAccept,
      );
      emit(
        ArenaFailure(
          data: state.data.copyWith(effects: const []),
          exception: exception,
        ),
      );
    }
  }

  Future<void> _onLevelSelected(ArenaLevelSelected event, Emitter<ArenaState> emit) async {
    final arena = _arena;
    if (state is! ArenaSuccess || arena == null || state.data.isReplaying) return;
    final level = state.data.levels.firstWhereOrNull((level) => level.id == event.levelId);
    if (level == null || !level.isPlayable) return;
    emit(
      ArenaSuccess(
        data: state.data.copyWith(
          selected: () => event.levelId,
          replay: () => null,
          result: () => null,
          fighters: _previewFighters(arena, event.levelId),
          effects: const [],
        ),
      ),
    );
  }

  Future<void> _onFightRequested(ArenaFightRequested event, Emitter<ArenaState> emit) async {
    final selected = state.data.selected;
    if (state is! ArenaSuccess || selected == null || !state.data.canFight) return;
    switch (_startFightUseCase(levelId: selected)) {
      case FightPlayedEntity(:final log, :final advice, :final isFirstChampionship):
        _advice = advice;
        _isFirstChampionship = isFirstChampionship;
        final replay = FightReplayData.start(log);
        emit(
          ArenaSuccess(
            data: state.data.copyWith(
              replay: () => replay,
              result: () => null,
              fighters: _replayFighters(replay),
              effects: const [],
            ),
          ),
        );
      case FightLockedEntity():
        _navigationService.showSnackbar(message: Internationalize.arenaMessageLocked);
    }
  }

  Future<void> _onReplayTicked(ArenaReplayTicked event, Emitter<ArenaState> emit) async {
    final replay = state.data.replay;
    if (state is! ArenaSuccess || replay == null || replay.isFinished) return;
    _emitReplay(replay, replay.advanced(event.deltaMs), emit);
  }

  Future<void> _onReplaySkipped(ArenaReplaySkipped event, Emitter<ArenaState> emit) async {
    final replay = state.data.replay;
    if (state is! ArenaSuccess || replay == null || replay.isFinished) return;
    _emitReplay(replay, replay.skipped(), emit, playTurns: false);
  }

  Future<void> _onClosed(ArenaClosed event, Emitter<ArenaState> emit) async {
    _navigationService.pop();
  }

  void _emitReplay(
    FightReplayData previous,
    FightReplayData next,
    Emitter<ArenaState> emit, {
    bool playTurns = true,
  }) {
    final effects = <ArenaEffect>[
      if (playTurns)
        for (var turn = previous.turnIndex + 1; turn <= next.turnIndex; turn++) ..._effectsFor(next, turn),
      if (next.isFinished) FightEndedEffect(isVictory: next.log.isVictory),
      if (next.isFinished && _isFirstChampionship) const ChampionEffect(),
    ];
    var data = state.data.copyWith(replay: () => next, fighters: _replayFighters(next), effects: effects);
    if (next.isFinished) {
      data = data.copyWith(result: () => _result(next));
      try {
        final arena = _getArenaUseCase();
        _arena = arena;
        data = _withArena(data, arena);
      } on AppException catch (exception) {
        _navigationService.showErrorPopUp(
          title: exception.title,
          message: exception.message,
          buttonTitle: Internationalize.commonAccept,
        );
      }
    }
    emit(ArenaSuccess(data: data));
  }

  List<ArenaEffect> _effectsFor(FightReplayData replay, int turnIndex) {
    final effect = _effectFor(replay, turnIndex);
    return switch (replay.log.turns[turnIndex].action) {
      FightAction.hit => [effect],
      FightAction.doubleStrike => [effect, const SkillUsedEffect(skill: SkillId.doubleStrike)],
      FightAction.dodge => [effect],
      FightAction.secondWind => [effect, const SkillUsedEffect(skill: SkillId.secondWind)],
    };
  }

  ArenaEffect _effectFor(FightReplayData replay, int turnIndex) {
    final turn = replay.log.turns[turnIndex];
    return switch (turn.action) {
      FightAction.hit || FightAction.doubleStrike => HitEffect(
        side: turn.target,
        index: turn.targetIndex,
        damage: turn.damage,
      ),
      FightAction.dodge => DodgeEffect(side: turn.target, index: turn.targetIndex),
      FightAction.secondWind => HealEffect(
        side: turn.target,
        index: turn.targetIndex,
        amount: turn.targetHealthAfter - replay.healthBefore(turnIndex, turn.target, turn.targetIndex),
      ),
    };
  }

  ArenaResultData _result(FightReplayData replay) {
    final log = replay.log;
    if (log.isVictory) {
      return ArenaResultData(
        isVictory: true,
        title: _isFirstChampionship ? Internationalize.arenaChampion : Internationalize.arenaVictory,
        detail: Internationalize.arenaReward(amount: log.reward[Resource.gold] ?? 0),
      );
    }
    final advice = _advice;
    return ArenaResultData(
      isVictory: false,
      title: Internationalize.arenaDefeat,
      detail: advice == null ? '' : Internationalize.arenaAdvice(advice: advice),
    );
  }

  ArenaData _withArena(ArenaData data, ArenaEntity arena) {
    return data.copyWith(
      heroPower: arena.heroPower,
      levels: [for (final status in arena.levels) _levelItem(status, heroPower: arena.heroPower)],
    );
  }

  ArenaLevelId? _defaultSelection(ArenaEntity arena) {
    final open = arena.levels.where((status) => status.isUnlocked);
    return (open.firstWhereOrNull((status) => !status.isCleared) ?? open.lastOrNull)?.level.id;
  }

  ArenaLevelItemData _levelItem(ArenaLevelStatusEntity status, {required int heroPower}) {
    final level = status.level;
    return ArenaLevelItemData(
      id: level.id,
      name: Internationalize.arenaLevel(id: level.id),
      enemiesText: _enemiesText(level),
      powerText: Internationalize.arenaPower(power: level.power),
      tone: _tone(levelPower: level.power, heroPower: heroPower),
      rewardText: Internationalize.arenaReward(amount: status.nextReward[Resource.gold] ?? 0),
      status: switch (status) {
        ArenaLevelStatusEntity(isCleared: true) => ArenaLevelItemStatus.cleared,
        ArenaLevelStatusEntity(isUnlocked: true) => ArenaLevelItemStatus.open,
        _ => ArenaLevelItemStatus.locked,
      },
    );
  }

  String _enemiesText(ArenaLevelEntity level) {
    final counts = <String, int>{};
    for (final enemy in level.enemies) {
      final name = Internationalize.arenaEnemy(kind: enemy.kind);
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts.entries
        .map(
          (entry) =>
              entry.value == 1 ? entry.key : Internationalize.arenaEnemyCount(count: entry.value, name: entry.key),
        )
        .join(', ');
  }

  PowerTone _tone({required int levelPower, required int heroPower}) {
    if (levelPower <= heroPower) return PowerTone.easy;
    if (levelPower <= heroPower * evenPowerRatio) return PowerTone.even;
    return PowerTone.hard;
  }

  List<FighterRenderData> _previewFighters(ArenaEntity arena, ArenaLevelId? selected) {
    final status = _getHeroStatusUseCase();
    final heroHealth = status.stats.health;
    _heroWeapon = Gear.of(GearSlot.weapon, status.hero.weaponTier).id;
    final level = arena.levels.firstWhereOrNull((status) => status.level.id == selected)?.level;
    return [
      FighterRenderData(
        side: FightSide.hero,
        index: 0,
        enemyKind: null,
        health: heroHealth,
        maxHealth: heroHealth,
        pose: FighterPose.idle,
        weapon: _heroWeapon,
      ),
      if (level != null)
        for (final (index, enemy) in level.enemies.indexed)
          FighterRenderData(
            side: FightSide.enemy,
            index: index,
            enemyKind: enemy.kind,
            health: enemy.stats.health,
            maxHealth: enemy.stats.health,
            pose: FighterPose.idle,
            isTargeted: index == 0,
          ),
    ];
  }

  List<FighterRenderData> _replayFighters(FightReplayData replay) {
    final log = replay.log;
    final target = _heroTarget(replay);
    return [
      _replayFighter(replay, FightSide.hero, 0, null),
      for (final (index, enemy) in log.enemies.indexed)
        _replayFighter(replay, FightSide.enemy, index, enemy.kind, isTargeted: index == target),
    ];
  }

  int _heroTarget(FightReplayData replay) {
    for (var index = 0; index < replay.log.enemies.length; index++) {
      if (replay.healthOf(FightSide.enemy, index) > 0) return index;
    }
    return -1;
  }

  FighterRenderData _replayFighter(
    FightReplayData replay,
    FightSide side,
    int index,
    EnemyKind? kind, {
    bool isTargeted = false,
  }) {
    final health = replay.healthOf(side, index);
    final swinging = replay.swingingTurn;
    final turn = swinging == null ? null : replay.log.turns[swinging];
    final progress = replay.swingProgress;
    final isActor = turn != null && turn.actor == side && turn.actorIndex == index;
    final isTarget = turn != null && turn.target == side && turn.targetIndex == index;
    final pose = switch (turn?.action) {
      _ when health == 0 => FighterPose.down,
      FightAction.hit || FightAction.doubleStrike || FightAction.dodge when isActor => FighterPose.attack,
      FightAction.hit || FightAction.doubleStrike
          when isTarget && turn.damage > 0 && progress >= ArenaRenderConstants.impactShare =>
        FighterPose.hurt,
      _ => FighterPose.idle,
    };
    return FighterRenderData(
      side: side,
      index: index,
      enemyKind: kind,
      health: health,
      maxHealth: replay.maxHealthOf(side, index),
      pose: pose,
      swingProgress: pose == FighterPose.attack ? progress : 0,
      targetIndex: pose == FighterPose.attack ? turn?.targetIndex ?? 0 : 0,
      isTargeted: isTargeted,
      weapon: side == FightSide.hero ? _heroWeapon : null,
    );
  }
}
