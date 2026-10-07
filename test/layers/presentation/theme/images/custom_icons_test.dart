import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/presentation/theme/images/custom_icons.dart';

void main() {
  test('testWhenResolvingEveryResourceIconThenTheSvgFileExists', () {
    // given
    final paths = Resource.values.map(CustomIcons.resource);

    // when
    final missing = paths.where((path) => !File(path).existsSync()).toList();

    // then
    expect(missing, isEmpty);
  });

  test('testWhenResolvingEveryToolIconThenTheSvgFileExists', () {
    // given
    final paths = ToolKind.values.map(CustomIcons.tool);

    // when
    final missing = paths.where((path) => !File(path).existsSync()).toList();

    // then
    expect(missing, isEmpty);
  });

  test('testWhenResolvingTheArenaIconThenTheSvgFileExists', () {
    // given
    const path = CustomIcons.arena;

    // when
    final exists = File(path).existsSync();

    // then
    expect(exists, isTrue);
  });
}
