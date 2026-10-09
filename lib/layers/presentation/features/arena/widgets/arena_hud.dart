import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../../forest/widgets/hud_button.dart';
import '../../forest/widgets/hud_panel.dart';
import '../models/arena_level_item_data.dart';
import '../models/arena_result_data.dart';
import 'fight_button.dart';
import 'level_list.dart';
import 'result_panel.dart';

class ArenaHud extends StatelessWidget {
  static const double _margin = 12;
  static const double _listTop = 64;

  final List<ArenaLevelItemData> levels;
  final ArenaLevelId? selected;
  final int heroPower;
  final bool isReplaying;
  final bool canFight;
  final ArenaResultData? result;
  final ValueChanged<ArenaLevelId> onLevelSelected;
  final VoidCallback onFight;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  const ArenaHud({
    super.key,
    required this.levels,
    required this.selected,
    required this.heroPower,
    required this.isReplaying,
    required this.canFight,
    required this.result,
    required this.onLevelSelected,
    required this.onFight,
    required this.onSkip,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final shownResult = result;
    return Stack(
      children: [
        Positioned(top: _margin, left: _margin, child: _header()),
        Positioned(
          top: _listTop,
          left: _margin,
          bottom: _margin,
          child: LevelList(levels: levels, selected: selected, isEnabled: !isReplaying, onSelected: onLevelSelected),
        ),
        Positioned(
          right: _margin,
          bottom: _margin,
          child: FightButton(isReplaying: isReplaying, canFight: canFight, onFight: onFight, onSkip: onSkip),
        ),
        if (shownResult != null && !isReplaying)
          Positioned(
            top: _margin,
            right: _margin,
            child: ResultPanel(result: shownResult, onRetry: onFight),
          ),
      ],
    );
  }

  Widget _header() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        HudButton(label: Internationalize.arenaBack, onPressed: onBack),
        HudPanel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Text(
                Internationalize.arenaTitle,
                style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudAccent),
              ),
              Text(
                Internationalize.arenaHeroPower(power: heroPower),
                style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
