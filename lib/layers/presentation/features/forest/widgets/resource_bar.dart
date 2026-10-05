import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/images/custom_icons.dart';
import '../../../theme/styles/custom_text_styles.dart';
import 'hud_panel.dart';

class ResourceBar extends StatelessWidget {
  static const Key axeKey = Key('resourceBarAxe');

  final int wood;
  final bool hasAxe;
  final bool showLabels;

  const ResourceBar({super.key, required this.wood, required this.hasAxe, this.showLabels = true});

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(mainAxisSize: MainAxisSize.min, spacing: 16, children: [_woodResource(), _axeResource()]),
    );
  }

  Widget _woodResource() {
    return Semantics(
      label: Internationalize.forestWood,
      value: '$wood',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          SvgPicture.asset(CustomIcons.wood, width: 22, height: 14, excludeFromSemantics: true),
          if (showLabels)
            Text(
              Internationalize.forestWood,
              style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 20),
            child: Text('$wood', style: CustomTextStyles.system18w600.copyWith(color: CustomColors.hudAccent)),
          ),
        ],
      ),
    );
  }

  Widget _axeResource() {
    return Opacity(
      key: axeKey,
      opacity: hasAxe ? 1 : 0.35,
      child: Semantics(
        label: Internationalize.forestAxe,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            SvgPicture.asset(CustomIcons.axe, width: 22, height: 22, excludeFromSemantics: true),
            if (showLabels)
              Text(
                Internationalize.forestAxe,
                style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText),
              ),
          ],
        ),
      ),
    );
  }
}
