import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../theme/colors/custom_colors.dart';
import 'custom_button_color.dart';
import 'custom_button_size.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final Function()? onPressed;
  final CustomButtonColor color;
  final BorderSide? border;
  final CustomButtonSize size;
  final IconData? leadingIcon;
  final String? leadingIconSvg;
  final double leadingIconSvgPadding;
  final double? elevation;
  final bool isLoading;
  final bool isDisabled;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = CustomButtonColor.dark,
    this.border,
    this.size = CustomButtonSize.standard,
    this.isLoading = false,
    this.isDisabled = false,
    this.leadingIcon,
    this.padding,
    this.elevation,
    this.leadingIconSvg,
    this.leadingIconSvgPadding = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size.size,
      child: ElevatedButton(
        style: ButtonStyle(
          elevation: WidgetStatePropertyAll(isDisabled ? 0 : elevation ?? 0),
          backgroundColor: isDisabled
              ? WidgetStatePropertyAll(color.backgroundDisable)
              : WidgetStatePropertyAll(color.background),
          foregroundColor: WidgetStatePropertyAll(color.foreground),
          padding: WidgetStatePropertyAll(padding),
          side: WidgetStatePropertyAll(isDisabled ? BorderSide(color: CustomColors.gray4) : border),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: .circular(16))),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (color == CustomButtonColor.dark && states.contains(WidgetState.pressed)) {
              return Colors.white.withAlpha(25);
            }
            return null;
          }),
        ),
        onPressed: isLoading || isDisabled ? null : onPressed,
        child: isLoading ? _loader() : _content(isDisabled),
      ),
    );
  }

  Widget _content(bool isDisabled) {
    return Row(
      mainAxisAlignment: .center,
      mainAxisSize: .min,
      spacing: size.spacing,
      children: [
        if (leadingIconSvg != null)
          SvgPicture.asset(
            leadingIconSvg!,
            width: 18,
            height: 18,
            colorFilter: .mode(isDisabled ? color.foregroundDisable : color.foreground, .srcIn),
          ),
        if (leadingIcon != null)
          Icon(leadingIcon!, size: size.iconSize, color: isDisabled ? color.foregroundDisable : color.foreground),
        Flexible(
          child: Text(
            label,
            textAlign: .center,
            softWrap: true,
            overflow: .visible,
            style: size.textStyle.copyWith(color: isDisabled ? color.foregroundDisable : color.foreground),
          ),
        ),
      ],
    );
  }

  Widget _loader() {
    return SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: color.foreground));
  }
}
