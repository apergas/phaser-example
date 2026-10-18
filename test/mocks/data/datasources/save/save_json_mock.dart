import 'dart:convert';

import 'save_dbo_mock.dart';

abstract final class SaveJsonMock {
  static final String valid = jsonEncode(SaveDBOMock.everything.toJson());
  static final String otherVersion = jsonEncode(SaveDBOMock.otherVersion.toJson());
  static final String versionOne = jsonEncode(SaveDBOMock.versionOne.toJson());
  static final String versionTwoWithAPickaxeOnTheGround = jsonEncode({
    ...SaveDBOMock.versionTwo.toJson(),
    'items': [
      {'id': 'pickaxe', 'kind': 'pickaxe', 'x': 1012, 'y': 812},
    ],
  });
  static final String outOfRange = jsonEncode(SaveDBOMock.withBadTree.toJson());
  static final String withoutPlayer = jsonEncode(SaveDBOMock.withoutPlayer.toJson());
  static const String broken = '{"version": 1, "width": 16';
  static const String notAnObject = '[1, 2, 3]';
  static const String wrongTypes = '{"version": "1"}';
  static const String empty = '{}';
  static const String notJson = 'hello';
}
