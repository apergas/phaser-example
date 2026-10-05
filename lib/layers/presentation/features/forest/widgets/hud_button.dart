import 'package:flutter/material.dart';

import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import 'hud_panel.dart';

class HudButton extends StatelessWidget {
  final String label;
  final String? badge;
  final VoidCallback? onPressed;
  final bool isActive;

  const HudButton({super.key, required this.label, this.badge, this.onPressed, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final badgeText = badge;
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: HudPanel(
        isHighlighted: isActive,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(6),
            hoverColor: CustomColors.hudAccentSoft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Text(label, style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText)),
                  if (badgeText != null) _badge(text: badgeText),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge({required String text}) {
    return DecoratedBox(
      decoration: BoxDecoration(color: CustomColors.hudAccent, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          text,
          style: CustomTextStyles.system12w600.copyWith(
            color: CustomColors.black,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
