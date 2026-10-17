import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../../forest/widgets/hud_button.dart';
import '../../forest/widgets/hud_panel.dart';
import '../models/arena_result_data.dart';

class ResultPanel extends StatelessWidget {
  static const double maxWidth = 280;

  final ArenaResultData result;
  final VoidCallback onRetry;
  final double width;

  const ResultPanel({super.key, required this.result, required this.onRetry, this.width = maxWidth});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: HudPanel(
        isHighlighted: result.isVictory,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(
              result.title,
              textAlign: TextAlign.center,
              style: CustomTextStyles.system18w600.copyWith(
                color: result.isVictory ? CustomColors.hudAccent : CustomColors.hudWarning,
              ),
            ),
            if (result.detail.isNotEmpty)
              Text(
                result.detail,
                textAlign: TextAlign.center,
                style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText),
              ),
            if (!result.isVictory)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: HudButton(label: Internationalize.arenaRetry, onPressed: onRetry),
              ),
          ],
        ),
      ),
    );
  }
}
