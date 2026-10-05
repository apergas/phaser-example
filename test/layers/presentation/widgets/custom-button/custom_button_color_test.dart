import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/theme/colors/custom_colors.dart';
import 'package:rpg/layers/presentation/widgets/custom-button/custom_button_color.dart';

void main() {
  test('testWhenReadingTheDisabledForegroundThenItDiffersFromTheDisabledBackgroundForEveryColor', () {
    // given
    const colors = CustomButtonColor.values;

    // when
    final clashing = colors.where((color) => color.foregroundDisable == color.backgroundDisable);

    // then
    expect(clashing, isEmpty);
  });

  test('testWhenReadingTheWarningForegroundThenItIsBlack', () {
    // given
    const color = CustomButtonColor.warning;

    // when
    final foreground = color.foreground;

    // then
    expect(foreground, CustomColors.black);
  });
}
