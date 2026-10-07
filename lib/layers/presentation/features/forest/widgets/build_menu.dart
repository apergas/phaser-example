import 'package:flutter/material.dart';

import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../models/build_item_data.dart';
import 'build_option_tile.dart';
import 'hud_panel.dart';

class BuildMenu extends StatelessWidget {
  final List<BuildItemData> items;
  final ValueChanged<BlueprintId> onSelected;

  const BuildMenu({super.key, required this.items, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      child: HudPanel(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              for (final item in items)
                BuildOptionTile(item: item, onPressed: item.isEnabled ? () => onSelected(item.blueprint) : null),
            ],
          ),
        ),
      ),
    );
  }
}
