import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/arena/arena_level_item_status.dart';
import '../../../../../core/config/constants/enum/arena/power_tone.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/images/custom_icons.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../../forest/widgets/hud_panel.dart';
import '../models/arena_level_item_data.dart';

class LevelTile extends StatelessWidget {
  final ArenaLevelItemData level;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const LevelTile({
    super.key,
    required this.level,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  static Color toneColor(PowerTone tone) => switch (tone) {
    PowerTone.easy => CustomColors.success,
    PowerTone.even => CustomColors.warning,
    PowerTone.hard => CustomColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final canTap = isEnabled && level.isPlayable;
    return Opacity(
      opacity: level.isPlayable ? 1 : 0.5,
      child: HudPanel(
        isHighlighted: isSelected,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: canTap ? onTap : null,
            borderRadius: BorderRadius.circular(6),
            hoverColor: CustomColors.hudAccentSoft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                spacing: 8,
                children: [
                  Expanded(child: _texts()),
                  _status(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _texts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(level.name, style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText)),
        Text(level.enemiesText, style: CustomTextStyles.system12w600.copyWith(color: CustomColors.hudMuted)),
        Wrap(
          spacing: 8,
          children: [
            Text(level.powerText, style: CustomTextStyles.system12w600.copyWith(color: toneColor(level.tone))),
            Text(level.rewardText, style: CustomTextStyles.system12w600.copyWith(color: CustomColors.hudAccent)),
          ],
        ),
      ],
    );
  }

  Widget _status() {
    return switch (level.status) {
      ArenaLevelItemStatus.locked => SvgPicture.asset(
        CustomIcons.lock,
        width: 18,
        height: 18,
        semanticsLabel: Internationalize.arenaLocked,
      ),
      ArenaLevelItemStatus.open => const SizedBox.shrink(),
      ArenaLevelItemStatus.cleared => Text(
        Internationalize.arenaCleared,
        style: CustomTextStyles.system12w600.copyWith(color: CustomColors.success),
      ),
    };
  }
}
