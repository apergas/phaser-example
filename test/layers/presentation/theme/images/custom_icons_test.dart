import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/layers/presentation/theme/images/custom_icons.dart';

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

  test('testWhenResolvingTheHeroIconThenTheSvgFileExists', () {
    // given
    const path = CustomIcons.hero;

    // when
    final exists = File(path).existsSync();

    // then
    expect(exists, isTrue);
  });

  test('testWhenResolvingTheArenaIconThenTheSvgFileExists', () {
    // given
    const path = CustomIcons.arena;

    // when
    final exists = File(path).existsSync();

    // then
    expect(exists, isTrue);
  });

  test('testWhenResolvingTheLockIconThenTheSvgFileExists', () {
    // given
    const path = CustomIcons.lock;

    // when
    final exists = File(path).existsSync();

    // then
    expect(exists, isTrue);
  });

  test('testWhenResolvingTheWorkshopAndSaveIconsThenTheSvgFilesExist', () {
    // given
    const paths = [CustomIcons.workshop, CustomIcons.save];

    // when
    final exists = paths.map((path) => File(path).existsSync()).toList();

    // then
    expect(exists, [true, true]);
  });

  test('testWhenResolvingTheQuestsAndBuildIconsThenTheSvgFilesExist', () {
    // given
    const paths = [CustomIcons.quests, CustomIcons.build];

    // when
    final exists = paths.map((path) => File(path).existsSync()).toList();

    // then
    expect(exists, [true, true]);
  });
}
