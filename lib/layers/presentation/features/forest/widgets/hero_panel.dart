import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/forest/hero_panel_section.dart';
import '../../../../../core/config/constants/enum/gear_id.dart';
import '../../../../../core/config/constants/enum/skill_id.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/hero_panel_data.dart';
import 'gear_row.dart';
import 'hud_button.dart';
import 'hud_panel.dart';
import 'skill_tile.dart';

class HeroPanel extends StatefulWidget {
  static const double reservedHeight = 96;

  final HeroPanelData hero;
  final ValueChanged<GearId> onBuy;
  final ValueChanged<SkillId>? onLearn;
  final List<HeroPanelSection> sections;

  const HeroPanel({
    super.key,
    required this.hero,
    required this.onBuy,
    this.onLearn,
    this.sections = const [HeroPanelSection.gear],
  }) : assert(sections.length > 0);

  @override
  State<HeroPanel> createState() => _HeroPanelState();
}

class _HeroPanelState extends State<HeroPanel> {
  late HeroPanelSection _section = widget.sections.first;

  @override
  void didUpdateWidget(HeroPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.sections.contains(_section)) {
      _section = widget.sections.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = math.max(0.0, MediaQuery.sizeOf(context).height - HeroPanel.reservedHeight);
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 260, maxWidth: 360, maxHeight: maxHeight),
      child: HudPanel(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [_title(), _stats(), if (widget.sections.length > 1) _tabs(), _body()],
          ),
        ),
      ),
    );
  }

  Widget _title() {
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: Text(
            Internationalize.forestHero.toUpperCase(),
            style: CustomTextStyles.system13w700.copyWith(color: CustomColors.hudMuted, letterSpacing: 0.78),
          ),
        ),
        if (widget.hero.isChampion) _championBadge(),
      ],
    );
  }

  Widget _championBadge() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CustomColors.hudAccentSoft,
        border: Border.all(color: CustomColors.hudAccent),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          Internationalize.forestHeroChampion,
          style: CustomTextStyles.system13w700.copyWith(color: CustomColors.hudAccent),
        ),
      ),
    );
  }

  Widget _stats() {
    final hero = widget.hero;
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _stat(label: Internationalize.forestHeroPower, value: hero.power, style: CustomTextStyles.system18w600),
        _stat(label: Internationalize.forestHeroAttack, value: hero.attack, style: CustomTextStyles.system15w600),
        _stat(label: Internationalize.forestHeroDefense, value: hero.defense, style: CustomTextStyles.system15w600),
        _stat(label: Internationalize.forestHeroHealth, value: hero.health, style: CustomTextStyles.system15w600),
      ],
    );
  }

  Widget _stat({required String label, required int value, required TextStyle style}) {
    return Semantics(
      label: label,
      value: '$value',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Text(label, style: CustomTextStyles.system13w500.copyWith(color: CustomColors.hudMuted)),
          Text(
            '$value',
            style: style.copyWith(color: CustomColors.hudAccent, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Row(
      spacing: 8,
      children: [
        for (final section in widget.sections)
          HudButton(
            label: Internationalize.forestHeroSection(section: section),
            isActive: section == _section,
            onPressed: () => setState(() => _section = section),
          ),
      ],
    );
  }

  Widget _body() {
    return switch (_section) {
      HeroPanelSection.gear => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [for (final row in widget.hero.rows) GearRow(row: row, onBuy: widget.onBuy)],
      ),
      HeroPanelSection.skills => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [for (final skill in widget.hero.skills) SkillTile(item: skill, onLearn: _onLearn(skill.id))],
      ),
    };
  }

  VoidCallback? _onLearn(SkillId id) {
    final onLearn = widget.onLearn;
    return onLearn == null ? null : () => onLearn(id);
  }
}
