import 'dart:io';

import 'package:flutter/services.dart';

Future<void> loadRobotoFont() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) throw StateError('FLUTTER_ROOT is not set: run the tests with flutter test');
  final loader = FontLoader('Roboto');
  for (final weight in const ['Regular', 'Medium', 'Bold']) {
    final file = File('$root/bin/cache/artifacts/material_fonts/Roboto-$weight.ttf');
    loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await loader.load();
}
