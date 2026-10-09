import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../forest/widgets/hud_button.dart';

class FightButton extends StatelessWidget {
  final bool isReplaying;
  final bool canFight;
  final VoidCallback onFight;
  final VoidCallback onSkip;

  const FightButton({
    super.key,
    required this.isReplaying,
    required this.canFight,
    required this.onFight,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    if (isReplaying) return HudButton(label: Internationalize.arenaSkip, onPressed: onSkip);
    return HudButton(label: Internationalize.arenaFight, isActive: canFight, onPressed: canFight ? onFight : null);
  }
}
