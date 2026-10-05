import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import 'hud_button.dart';

class PlacementBar extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const PlacementBar({super.key, required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            HudButton(label: Internationalize.forestPlacementConfirm, isActive: true, onPressed: onConfirm),
            HudButton(label: Internationalize.forestPlacementCancel, onPressed: onCancel),
          ],
        ),
      ),
    );
  }
}
