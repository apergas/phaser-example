import 'dart:math';

import '../../entities/tree/stump_entity.dart';
import '../../rules/rules.dart';

extension StumpRules on StumpEntity {
  bool get isSapling => elapsedMs >= Rules.sproutAfterMs;

  bool get isReadyToRegrow => elapsedMs >= Rules.regrowAfterMs;

  StumpEntity grown(double deltaMs) => copyWith(elapsedMs: min(elapsedMs + deltaMs, Rules.regrowAfterMs));
}
