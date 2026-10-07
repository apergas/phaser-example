import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/fight_side.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../forest/game/components/floating_text_component.dart';
import '../../forest/game/particles/particle_burst_component.dart';
import '../../forest/game/particles/particle_bursts.dart';
import '../bloc/arena_bloc.dart';
import '../models/arena_effect.dart';
import '../models/fighter_render_data.dart';
import 'atlas/arena_assets.dart';
import 'components/arena_ground_component.dart';
import 'components/fighter_component.dart';

class ArenaSceneComponent extends Component {
  final ArenaAssets _assets;
  final math.Random _random;
  final Map<String, FighterComponent> _fighters = {};
  bool _isBuilt = false;

  ArenaSceneComponent({required this._assets, math.Random? random}) : _random = random ?? math.Random();

  Map<String, FighterComponent> get fighters => Map.unmodifiable(_fighters);

  void show(ArenaData data) {
    if (!_isBuilt) {
      _isBuilt = true;
      add(ArenaGroundComponent(assets: _assets));
    }
    _reconcile(data.fighters);
    for (final effect in data.effects) {
      _play(effect);
    }
  }

  void _reconcile(List<FighterRenderData> fighters) {
    final keys = {for (final fighter in fighters) fighter.key};
    for (final key in _fighters.keys.where((key) => !keys.contains(key)).toList()) {
      _removeFighter(_fighters.remove(key)!);
    }
    for (final fighter in fighters) {
      final current = _fighters[fighter.key];
      if (current != null && current.fighter.enemyKind == fighter.enemyKind) {
        current.show(fighter);
        continue;
      }
      if (current != null) {
        _removeFighter(current);
      }
      final created = FighterComponent(assets: _assets, fighter: fighter);
      _fighters[fighter.key] = created;
      add(created.shadow);
      add(created.healthBar);
      add(created);
    }
  }

  void _play(ArenaEffect effect) {
    switch (effect) {
      case HitEffect(:final side, :final index, :final damage):
        _onHit(side, index, damage);
      case DodgeEffect(:final side, :final index):
        _float(side, index, Internationalize.arenaDodge, FloatingTextComponent.defaultColor);
      case HealEffect(:final side, :final index, :final amount):
        _float(side, index, Internationalize.arenaHeal(amount: amount), CustomColors.success);
      case FightEndedEffect():
        for (final fighter in _fighters.values) {
          fighter.healthBar.snap();
        }
    }
  }

  void _removeFighter(FighterComponent fighter) {
    fighter.shadow.removeFromParent();
    fighter.healthBar.removeFromParent();
    fighter.removeFromParent();
  }

  void _onHit(FightSide side, int index, int damage) {
    final fighter = _fighters[FighterRenderData.keyOf(side, index)];
    if (fighter == null) return;
    _float(side, index, Internationalize.arenaDamage(amount: damage), CustomColors.hudWarning);
    if (damage <= 0) return;
    fighter.hit();
    final impact = fighter.impactPoint;
    add(
      ParticleBurstComponent(
        particles: ParticleBursts.bloodDrops(
          impact: impact,
          attackerOnLeft: side == FightSide.enemy,
          random: _random,
        ),
        sortY: fighter.position.y,
      ),
    );
  }

  void _float(FightSide side, int index, String text, Color color) {
    final fighter = _fighters[FighterRenderData.keyOf(side, index)];
    if (fighter == null) return;
    add(FloatingTextComponent(text: text, at: fighter.headPoint, color: color));
  }
}
