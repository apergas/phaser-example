import 'package:flutter/material.dart';

import '../../../../../core/config/constants/enum/forest/quest_item_status.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/quest_item_data.dart';

class QuestRow extends StatelessWidget {
  static const Key decorationKey = Key('questRowDecoration');
  static const Key checkKey = Key('questRowCheck');

  final QuestItemData quest;

  const QuestRow({super.key, required this.quest});

  bool get _isCurrent => quest.status == QuestItemStatus.current;

  bool get _isDone => quest.status == QuestItemStatus.done;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: decorationKey,
      decoration: BoxDecoration(
        color: _isCurrent ? CustomColors.hudAccentSoft : null,
        border: Border.all(color: _isCurrent ? CustomColors.hudAccent : CustomColors.transparent),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          spacing: 10,
          children: [
            _check(),
            Expanded(child: Text(quest.title, style: _titleStyle())),
            Text(
              quest.progressText,
              softWrap: false,
              style: CustomTextStyles.system13w500.copyWith(
                color: _isDone ? CustomColors.questDone : CustomColors.hudAccent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _check() {
    final color = switch (quest.status) {
      QuestItemStatus.done => CustomColors.questDone,
      QuestItemStatus.current => CustomColors.hudAccent,
      QuestItemStatus.pending => CustomColors.hudMuted,
    };
    return Container(
      key: checkKey,
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(2),
      child: _isDone ? const ColoredBox(color: CustomColors.questDone) : null,
    );
  }

  TextStyle _titleStyle() {
    final color = switch (quest.status) {
      QuestItemStatus.done || QuestItemStatus.pending => CustomColors.hudMuted,
      QuestItemStatus.current => CustomColors.hudText,
    };
    return CustomTextStyles.system15w600.copyWith(
      color: color,
      decoration: _isDone ? TextDecoration.lineThrough : null,
    );
  }
}
