import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import 'hud_button.dart';
import 'hud_panel.dart';

class PlacementBar extends StatelessWidget {
  final String? reason;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const PlacementBar({super.key, required this.reason, required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            _reasonLabel(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: [
                HudButton(label: Internationalize.forestPlacementConfirm, isActive: true, onPressed: onConfirm),
                HudButton(label: Internationalize.forestPlacementCancel, onPressed: onCancel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reasonLabel() {
    final text = reason;
    return ExcludeSemantics(
      excluding: text == null,
      child: Opacity(
        opacity: text == null ? 0 : 1,
        child: HudPanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            text ?? ' ',
            textAlign: TextAlign.center,
            style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudWarning),
          ),
        ),
      ),
    );
  }
}
