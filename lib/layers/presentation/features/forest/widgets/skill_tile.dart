import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/skill_id.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/skill_item_data.dart';
import 'hud_button.dart';

class SkillTile extends StatelessWidget {
  final SkillItemData item;
  final VoidCallback? onLearn;

  const SkillTile({super.key, required this.item, this.onLearn});

  static Key learnKey(SkillId id) => Key('skillTileLearn-${id.name}');

  @override
  Widget build(BuildContext context) {
    final levelText = item.levelText;
    final nextText = item.nextText;
    final costText = item.costText;
    final reasonText = item.reasonText;
    final buttonText = item.buttonText;
    return DecoratedBox(
      decoration: BoxDecoration(color: CustomColors.hudOptionBackground, borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          spacing: 10,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Row(
                    spacing: 6,
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: CustomTextStyles.system15w600.copyWith(
                            color: item.isKnown || item.canLearn ? CustomColors.hudText : CustomColors.hudMuted,
                          ),
                        ),
                      ),
                      if (levelText != null)
                        Text(
                          levelText,
                          style: CustomTextStyles.system12w500.copyWith(
                            color: CustomColors.hudAccent,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                  Text(item.description, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudMuted)),
                  if (nextText != null)
                    Text(nextText, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudText)),
                  if (costText != null)
                    Text(
                      costText,
                      style: CustomTextStyles.system13w500.copyWith(
                        color: item.canLearn ? CustomColors.hudAccent : CustomColors.hudMuted,
                      ),
                    ),
                  if (reasonText != null)
                    Text(reasonText, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudWarning)),
                ],
              ),
            ),
            if (buttonText != null)
              HudButton(key: learnKey(item.id), label: buttonText, onPressed: item.canLearn ? onLearn : null)
            else
              Text(
                Internationalize.forestHeroSkillMax,
                style: CustomTextStyles.system12w500.copyWith(color: CustomColors.questDone),
              ),
          ],
        ),
      ),
    );
  }
}
