import 'package:flutter/material.dart';

import '../../../../../core/config/constants/enum/arena_level_id.dart';
import '../models/arena_level_item_data.dart';
import 'level_tile.dart';

class LevelList extends StatelessWidget {
  static const double maxWidth = 280;

  final List<ArenaLevelItemData> levels;
  final ArenaLevelId? selected;
  final bool isEnabled;
  final ValueChanged<ArenaLevelId> onSelected;

  const LevelList({
    super.key,
    required this.levels,
    required this.selected,
    required this.isEnabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            for (final level in levels)
              LevelTile(
                level: level,
                isSelected: level.id == selected,
                isEnabled: isEnabled,
                onTap: () => onSelected(level.id),
              ),
          ],
        ),
      ),
    );
  }
}
