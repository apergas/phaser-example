import 'package:flutter/material.dart';

import '../../../theme/colors/custom_colors.dart';

class HudPanel extends StatelessWidget {
  static const Key decorationKey = Key('hudPanelDecoration');

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool isHighlighted;

  const HudPanel({super.key, required this.child, this.padding = EdgeInsets.zero, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: decorationKey,
      decoration: BoxDecoration(
        color: CustomColors.hudBackground,
        border: Border.all(color: isHighlighted ? CustomColors.hudAccent : CustomColors.hudBorder, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: CustomColors.hudShadow, offset: Offset(0, 2))],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
