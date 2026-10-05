import 'package:flutter/material.dart';

import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/build_item_data.dart';

class BuildOptionTile extends StatelessWidget {
  final BuildItemData item;
  final VoidCallback? onPressed;

  const BuildOptionTile({super.key, required this.item, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final missingText = item.missingText;
    return Material(
      color: CustomColors.hudOptionBackground,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        hoverColor: CustomColors.hudAccentSoft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: CustomTextStyles.system15w600.copyWith(
                        color: item.isEnabled ? CustomColors.hudText : CustomColors.hudMuted,
                      ),
                    ),
                  ),
                  Text(
                    item.costText,
                    style: CustomTextStyles.system13w500.copyWith(
                      color: item.isEnabled ? CustomColors.hudAccent : CustomColors.hudMuted,
                    ),
                  ),
                ],
              ),
              if (missingText != null)
                Text(missingText, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudWarning)),
            ],
          ),
        ),
      ),
    );
  }
}
