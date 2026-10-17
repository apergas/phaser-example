import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/upgrade_id.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/upgrade_item_data.dart';
import 'hud_button.dart';

class UpgradeOptionTile extends StatelessWidget {
  final UpgradeItemData item;
  final VoidCallback? onBuy;

  const UpgradeOptionTile({super.key, required this.item, this.onBuy});

  static Key buyKey(UpgradeId id) => Key('upgradeOptionTileBuy-${id.name}');

  @override
  Widget build(BuildContext context) {
    final reasonText = item.reasonText;
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
                  Text(
                    item.name,
                    style: CustomTextStyles.system15w600.copyWith(
                      color: item.canBuy ? CustomColors.hudText : CustomColors.hudMuted,
                    ),
                  ),
                  Text(item.effectText, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudMuted)),
                  Text(
                    item.costText,
                    style: CustomTextStyles.system13w500.copyWith(
                      color: item.canBuy ? CustomColors.hudAccent : CustomColors.hudMuted,
                    ),
                  ),
                  if (reasonText != null)
                    Text(reasonText, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudWarning)),
                ],
              ),
            ),
            HudButton(
              key: buyKey(item.id),
              label: Internationalize.forestHeroBuy,
              onPressed: item.canBuy ? onBuy : null,
            ),
          ],
        ),
      ),
    );
  }
}
