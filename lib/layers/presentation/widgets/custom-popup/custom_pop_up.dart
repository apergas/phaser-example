import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../theme/colors/custom_colors.dart';
import '../../theme/styles/custom_text_styles.dart';
import '../custom-button/custom_button.dart';

enum ActionsDirection { vertical, horizontal }

class CustomPopUp extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final List<CustomButton> actions;
  final ActionsDirection actionsDirection;
  final String? icon;
  final String? image;
  final Color? textColor;

  Color get _resolvedTextColor => textColor ?? CustomColors.hudText;

  bool get hasTopWidget => icon != null || image != null;

  EdgeInsets get topPadding {
    if (icon != null) {
      return const .only(top: 8, left: 24, right: 24);
    }

    if (image != null) {
      return const .only(top: 24, left: 24, right: 24);
    }

    return const .only(top: 32, left: 24, right: 24);
  }

  const CustomPopUp({
    super.key,
    required this.title,
    required this.actions,
    this.actionsDirection = ActionsDirection.horizontal,
    this.textColor = CustomColors.hudText,
    this.icon,
    this.image,
    this.message,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      alignment: .center,
      titlePadding: topPadding,
      actionsPadding: const .only(left: 16, right: 16, bottom: 16, top: 16),
      actionsAlignment: .center,
      contentPadding: const .symmetric(horizontal: 24, vertical: 16),
      insetPadding: const .all(32),
      title: !hasTopWidget ? _plainTitle() : _titleWithTopWidget(),
      content: message != null
          ? Text(
              message!,
              textAlign: .left,
              style: CustomTextStyles.system16w400.copyWith(color: _resolvedTextColor),
            )
          : content,
      actions: [_actions()],
    );
  }

  Widget _plainTitle() {
    return Text(
      title,
      textAlign: .left,
      style: CustomTextStyles.system24w400.copyWith(color: _resolvedTextColor),
    );
  }

  Widget _titleWithTopWidget() {
    return Column(
      children: [
        if (icon != null)
          Padding(
            padding: const .only(bottom: 16),
            child: SvgPicture.asset(icon!, height: 32, width: 32),
          ),
        if (image != null)
          Padding(
            padding: const .only(bottom: 32),
            child: Image.asset(image!, height: 120, width: 120, fit: .cover),
          ),
        Text(
          title,
          textAlign: .center,
          style: CustomTextStyles.system24w400.copyWith(color: _resolvedTextColor),
        ),
      ],
    );
  }

  Widget _actions() {
    return actionsDirection == .vertical
        ? Column(
            mainAxisSize: .min,
            spacing: 16,
            children: actions.map((action) => Row(children: [Expanded(child: action)])).toList(),
          )
        : Row(spacing: 16, children: actions.map((action) => Expanded(child: action)).toList());
  }
}
