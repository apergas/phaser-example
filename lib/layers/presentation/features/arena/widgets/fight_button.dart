import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../forest/widgets/hud_button.dart';

class FightButton extends StatelessWidget {
  final bool isReplaying;
  final bool canFight;
  final VoidCallback onFight;

  const FightButton({super.key, required this.isReplaying, required this.canFight, required this.onFight});

  @override
  Widget build(BuildContext context) {
    if (isReplaying) return const SizedBox.shrink();
    return HudButton(label: Internationalize.arenaFight, isActive: canFight, onPressed: canFight ? onFight : null);
  }
}
