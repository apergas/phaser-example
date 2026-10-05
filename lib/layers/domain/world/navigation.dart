import '../entities/game/game_event_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/player/activity_entity.dart';
import '../entities/player/intent_entity.dart';
import '../rules/rules.dart';
import 'extensions/player_rules.dart';
import 'extensions/position_geometry.dart';
import 'work.dart';
import 'world_state.dart';

const double _reachTolerance = 6;

class Navigation {
  Navigation(this._state);

  final WorldState _state;

  void walkTo(PositionEntity destination) {
    _state.player = _state.player.walkTo(_state.clamp(destination, _state.player.radius));
  }

  void goWorkOn(IntentEntity intent) {
    if (_isWithinReach(intent)) {
      _startWork(intent);
      return;
    }
    _state.player = _state.player.walkTo(_workSpot(intent), intent: intent);
  }

  void step(double deltaMs, WalkingActivityEntity activity, List<GameEventEntity> events) {
    final player = _state.player;
    final next = player.nextPosition(deltaMs);
    if (next == null) return;
    final intent = activity.intent;

    if (_state.isBlocked(next, player.radius)) {
      if (intent != null && _isWithinReach(intent)) {
        _startWork(intent);
        return;
      }
      if (intent != null) events.add(const PlayerBlockedEventEntity());
      _state.player = player.stop();
      return;
    }

    _state.player = player.placeAt(next);
    if (next != activity.destination) return;
    if (intent != null) {
      _startWork(intent);
    } else {
      _state.player = _state.player.stop();
    }
  }

  void _startWork(IntentEntity intent) {
    _state.player = workFor(intent).target(_state) != null ? _state.player.startWork(intent) : _state.player.stop();
  }

  bool _isWithinReach(IntentEntity intent) {
    final target = workFor(intent).target(_state);
    if (target == null) return false;
    final reach = target.radius + _state.player.radius + Rules.workGap + _reachTolerance;
    return _state.player.position.distanceTo(target.position) <= reach;
  }

  PositionEntity _workSpot(IntentEntity intent) {
    final player = _state.player;
    final work = workFor(intent);
    final target = work.target(_state);
    if (target == null) return player.position;
    final distance = target.radius + player.radius + Rules.workGap;
    final side = player.position.x < target.position.x ? -1 : 1;
    bool isFree(PositionEntity spot) => _state.isInside(spot, player.radius) && !_state.isBlocked(spot, player.radius);

    for (final spot in work.preferredSpots(target, distance, side)) {
      if (isFree(spot)) return spot;
    }
    return _state.clamp(target.position.pointAtDistance(distance, player.position), player.radius);
  }
}
