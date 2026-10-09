import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/quest_line.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/quest_item_data.dart';
import 'hud_panel.dart';
import 'quest_row.dart';

class QuestPanel extends StatelessWidget {
  final List<QuestItemData> quests;

  const QuestPanel({super.key, required this.quests});

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
            children: [
              _title(),
              for (final line in QuestLine.values) ..._section(line),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _section(QuestLine line) {
    final rows = quests.where((quest) => quest.line == line);
    if (rows.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
        child: Text(
          Internationalize.forestQuestLine(line: line),
          style: CustomTextStyles.system13w700.copyWith(color: CustomColors.hudAccent),
        ),
      ),
      for (final quest in rows) QuestRow(quest: quest),
    ];
  }

  Widget _title() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Text(
        Internationalize.forestQuests.toUpperCase(),
        style: CustomTextStyles.system13w700.copyWith(color: CustomColors.hudMuted, letterSpacing: 0.78),
      ),
    );
  }
}
