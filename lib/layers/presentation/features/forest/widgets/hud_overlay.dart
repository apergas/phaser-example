import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../../core/config/constants/enum/forest/hud_menu.dart';
import '../../../../../core/config/constants/enum/gear_id.dart';
import '../../../theme/images/custom_icons.dart';
import '../models/hud_data.dart';
import 'build_menu.dart';
import 'hero_panel.dart';
import 'hud_button.dart';
import 'quest_panel.dart';
import 'resource_bar.dart';

class HudOverlay extends StatefulWidget {
  static const double narrowWidth = 480;
  static const double buttonsBelowWidth = 920;
  static const double _margin = 12;

  final HudData hud;
  final ValueChanged<BlueprintId> onBuildSelected;
  final ValueChanged<GearId> onGearSelected;
  final VoidCallback onArenaPressed;

  const HudOverlay({
    super.key,
    required this.hud,
    required this.onBuildSelected,
    required this.onGearSelected,
    required this.onArenaPressed,
  });

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  HudMenu? _openMenu;

  @override
  void didUpdateWidget(HudOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hud.isBuildLocked && _openMenu == HudMenu.build) {
      _openMenu = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final resourceBar = ResourceBar(
      resources: widget.hud.resources,
      tools: widget.hud.tools,
      showLabels: width >= HudOverlay.narrowWidth,
    );
    final maxWidth = width - 2 * HudOverlay._margin;
    if (width < HudOverlay.buttonsBelowWidth) {
      return Stack(
        children: [
          Positioned(
            top: HudOverlay._margin,
            left: HudOverlay._margin,
            right: HudOverlay._margin,
            bottom: HudOverlay._margin,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Align(alignment: Alignment.centerLeft, child: resourceBar),
                Flexible(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: _actions(maxWidth: maxWidth, isHeightBounded: true),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Stack(
      children: [
        Positioned(top: HudOverlay._margin, left: HudOverlay._margin, child: resourceBar),
        Positioned(
          top: HudOverlay._margin,
          right: HudOverlay._margin,
          child: _actions(maxWidth: maxWidth),
        ),
      ],
    );
  }

  Widget _actions({required double maxWidth, bool isHeightBounded = false}) {
    final openMenu = _openMenu;
    final menu = openMenu == null ? null : _menu(menu: openMenu);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth < 0 ? 0 : maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 8,
        children: [
          _buttons(),
          if (menu != null) isHeightBounded ? Flexible(child: menu) : menu,
        ],
      ),
    );
  }

  Widget _buttons() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: _buttonRow(),
    );
  }

  Widget _buttonRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        HudButton(
          label: Internationalize.forestQuests,
          badge: widget.hud.questBadge,
          isActive: _openMenu == HudMenu.quests,
          onPressed: () => _toggle(HudMenu.quests),
        ),
        HudButton(
          label: Internationalize.forestBuild,
          isActive: _openMenu == HudMenu.build,
          onPressed: widget.hud.isBuildLocked ? null : () => _toggle(HudMenu.build),
        ),
        HudButton(
          label: Internationalize.forestHero,
          icon: CustomIcons.hero,
          isActive: _openMenu == HudMenu.hero,
          onPressed: () => _toggle(HudMenu.hero),
        ),
        HudButton(label: Internationalize.forestArena, icon: CustomIcons.arena, onPressed: _onArenaPressed),
      ],
    );
  }

  Widget _menu({required HudMenu menu}) {
    return switch (menu) {
      HudMenu.quests => QuestPanel(quests: widget.hud.quests),
      HudMenu.build => BuildMenu(items: widget.hud.buildItems, onSelected: _onBuildSelected),
      HudMenu.hero => HeroPanel(hero: widget.hud.hero, onBuy: widget.onGearSelected),
    };
  }

  void _toggle(HudMenu menu) {
    setState(() => _openMenu = _openMenu == menu ? null : menu);
  }

  void _onArenaPressed() {
    setState(() => _openMenu = null);
    widget.onArenaPressed();
  }

  void _onBuildSelected(BlueprintId blueprint) {
    setState(() => _openMenu = null);
    widget.onBuildSelected(blueprint);
  }
}
