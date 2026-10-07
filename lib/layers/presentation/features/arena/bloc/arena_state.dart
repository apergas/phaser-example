part of 'arena_bloc.dart';

class ArenaData {
  final List<ArenaLevelItemData> levels;
  final ArenaLevelId? selected;
  final int heroPower;
  final FightReplayData? replay;
  final List<FighterRenderData> fighters;
  final ArenaResultData? result;
  final List<ArenaEffect> effects;

  const ArenaData({
    this.levels = const [],
    this.selected,
    this.heroPower = 0,
    this.replay,
    this.fighters = const [],
    this.result,
    this.effects = const [],
  });

  bool get isReplaying => replay?.isFinished == false;

  bool get canFight => !isReplaying && levels.any((level) => level.id == selected && level.isPlayable);

  ArenaData copyWith({
    List<ArenaLevelItemData>? levels,
    ValueGetter<ArenaLevelId?>? selected,
    int? heroPower,
    ValueGetter<FightReplayData?>? replay,
    List<FighterRenderData>? fighters,
    ValueGetter<ArenaResultData?>? result,
    List<ArenaEffect>? effects,
  }) {
    return ArenaData(
      levels: levels ?? this.levels,
      selected: selected != null ? selected() : this.selected,
      heroPower: heroPower ?? this.heroPower,
      replay: replay != null ? replay() : this.replay,
      fighters: fighters ?? this.fighters,
      result: result != null ? result() : this.result,
      effects: effects ?? this.effects,
    );
  }
}

sealed class ArenaState {
  final ArenaData data;

  const ArenaState({required this.data});
}

final class ArenaInitial extends ArenaState {
  const ArenaInitial() : super(data: const ArenaData());
}

final class ArenaInProgress extends ArenaState {
  const ArenaInProgress({required super.data});
}

final class ArenaSuccess extends ArenaState {
  const ArenaSuccess({required super.data});
}

final class ArenaFailure extends ArenaState {
  final CustomException exception;

  const ArenaFailure({required super.data, required this.exception});
}
