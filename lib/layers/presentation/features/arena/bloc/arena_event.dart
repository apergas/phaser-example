part of 'arena_bloc.dart';

sealed class ArenaEvent {
  const ArenaEvent();
}

final class ArenaStarted extends ArenaEvent {
  const ArenaStarted();
}

final class ArenaLevelSelected extends ArenaEvent {
  final ArenaLevelId levelId;

  const ArenaLevelSelected({required this.levelId});
}

final class ArenaFightRequested extends ArenaEvent {
  const ArenaFightRequested();
}

final class ArenaReplayTicked extends ArenaEvent {
  final double deltaMs;

  const ArenaReplayTicked({required this.deltaMs});
}

final class ArenaReplaySkipped extends ArenaEvent {
  const ArenaReplaySkipped();
}

final class ArenaClosed extends ArenaEvent {
  const ArenaClosed();
}
