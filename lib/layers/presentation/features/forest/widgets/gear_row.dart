import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/gear_id.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/gear_row_data.dart';
import 'gear_option_tile.dart';

class GearRow extends StatelessWidget {
  final GearRowData row;
  final ValueChanged<GearId> onBuy;

  const GearRow({super.key, required this.row, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final next = row.next;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(
          row.title.toUpperCase(),
          style: CustomTextStyles.system12w700.copyWith(color: CustomColors.hudMuted, letterSpacing: 0.72),
        ),
        _equipped(),
        if (next != null)
          GearOptionTile(item: next, onBuy: () => onBuy(next.id))
        else
          Text(
            Internationalize.forestHeroMaxed,
            style: CustomTextStyles.system12w500.copyWith(color: CustomColors.questDone),
          ),
      ],
    );
  }

  Widget _equipped() {
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(row.equipped.name, style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText)),
              Text(
                row.equipped.statsText,
                style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudAccent),
              ),
            ],
          ),
        ),
        Text(
          Internationalize.forestHeroEquipped,
          style: CustomTextStyles.system12w500.copyWith(color: CustomColors.questDone),
        ),
      ],
    );
  }
}
