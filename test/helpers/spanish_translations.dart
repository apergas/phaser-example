// ignore_for_file: implementation_imports
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';

void loadSpanishTranslations() {
  final file = File('lib/core/assets/i18n/translations/es.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  Localization.load(const Locale('es'), translations: Translations(json));
}
