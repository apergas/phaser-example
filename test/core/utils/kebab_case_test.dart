import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/utils/kebab_case.dart';

void main() {
  test('testWhenNameHasSeveralWordsThenJoinsThemWithHyphens', () {
    // given
    const name = 'tallGrass';

    // when
    final kebab = name.toKebabCase();

    // then
    expect(kebab, 'tall-grass');
  });

  test('testWhenNameHasOneWordThenKeepsItLowerCase', () {
    // given
    const name = 'oak';

    // when
    final kebab = name.toKebabCase();

    // then
    expect(kebab, 'oak');
  });

  test('testWhenNameStartsWithAnUpperCaseLetterThenDoesNotAddALeadingHyphen', () {
    // given
    const name = 'TallGrass';

    // when
    final kebab = name.toKebabCase();

    // then
    expect(kebab, 'tall-grass');
  });
}
