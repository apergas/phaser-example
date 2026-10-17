import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/upgrade_id.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/upgrade_item_data.dart';
import 'hud_panel.dart';
import 'upgrade_option_tile.dart';

class UpgradeMenu extends StatelessWidget {
  final List<UpgradeItemData> items;
  final ValueChanged<UpgradeId> onBuy;

  const UpgradeMenu({super.key, required this.items, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 340),
      child: HudPanel(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Semantics(
                  header: true,
                  child: Text(
                    Internationalize.forestUpgradeTitle.toUpperCase(),
                    style: CustomTextStyles.system13w700.copyWith(color: CustomColors.hudMuted, letterSpacing: 0.78),
                  ),
                ),
              ),
              for (final item in items) UpgradeOptionTile(item: item, onBuy: () => onBuy(item.id)),
            ],
          ),
        ),
      ),
    );
  }
}
