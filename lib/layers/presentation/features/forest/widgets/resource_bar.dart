import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/tool_kind.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/images/custom_icons.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/resource_item_data.dart';
import '../models/tool_item_data.dart';
import 'hud_panel.dart';

class ResourceBar extends StatelessWidget {
  final List<ResourceItemData> stock;
  final List<ToolItemData> tools;
  final bool showLabels;

  const ResourceBar({
    super.key,
    required this.stock,
    required this.tools,
    this.showLabels = true,
  });

  static Key toolKey(ToolKind tool) => Key('resourceBarTool-${tool.name}');

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          if (showLabels)
            Text(
              Internationalize.forestStock,
              style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudMuted),
            ),
          for (final resource in stock) _resource(resource),
          for (final tool in tools) _tool(tool),
        ],
      ),
    );
  }

  Widget _resource(ResourceItemData resource) {
    return Semantics(
      label: resource.name,
      value: '${resource.amount}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          SvgPicture.asset(CustomIcons.resource(resource.resource), width: 22, height: 14, excludeFromSemantics: true),
          if (showLabels)
            Text(resource.name, style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText)),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 20),
            child: Text(
              '${resource.amount}',
              style: CustomTextStyles.system18w600.copyWith(
                color: CustomColors.hudAccent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tool(ToolItemData tool) {
    return Opacity(
      key: toolKey(tool.tool),
      opacity: tool.isOwned ? 1 : 0.35,
      child: Semantics(
        label: tool.name,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            SvgPicture.asset(CustomIcons.tool(tool.tool), width: 22, height: 22, excludeFromSemantics: true),
            if (showLabels) Text(tool.name, style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText)),
          ],
        ),
      ),
    );
  }
}
