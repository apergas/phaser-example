import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import 'hud_button.dart';
import 'hud_panel.dart';

class GamePanel extends StatefulWidget {
  static const Key saveKey = Key('gamePanelSave');
  static const Key newGameKey = Key('gamePanelNewGame');
  static const Key confirmKey = Key('gamePanelConfirm');
  static const Key cancelKey = Key('gamePanelCancel');

  final VoidCallback onSave;
  final VoidCallback onNewGame;

  const GamePanel({super.key, required this.onSave, required this.onNewGame});

  @override
  State<GamePanel> createState() => _GamePanelState();
}

class _GamePanelState extends State<GamePanel> {
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 340),
      child: HudPanel(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Semantics(
                  header: true,
                  child: Text(
                    Internationalize.forestGame.toUpperCase(),
                    style: CustomTextStyles.system13w700.copyWith(color: CustomColors.hudMuted, letterSpacing: 0.78),
                  ),
                ),
              ),
              if (_isConfirming) ..._confirmation() else _actions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        HudButton(key: GamePanel.saveKey, label: Internationalize.forestGameSave, onPressed: widget.onSave),
        HudButton(
          key: GamePanel.newGameKey,
          label: Internationalize.forestGameNewGame,
          onPressed: () => setState(() => _isConfirming = true),
        ),
      ],
    );
  }

  List<Widget> _confirmation() {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          Internationalize.forestGameNewGameConfirm,
          style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText),
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          HudButton(key: GamePanel.confirmKey, label: Internationalize.forestGameConfirm, onPressed: widget.onNewGame),
          HudButton(
            key: GamePanel.cancelKey,
            label: Internationalize.forestGameCancel,
            onPressed: () => setState(() => _isConfirming = false),
          ),
        ],
      ),
    ];
  }
}
