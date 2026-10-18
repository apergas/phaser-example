import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/services/logging/source/logger.dart';
import '../source/game_save_local_datasource.dart';
import 'dbo/save_dbo.dart';

@LazySingleton(as: GameSaveLocalDatasource)
class GameSaveLocalDatasourceImpl implements GameSaveLocalDatasource {
  static const String _key = 'farming.save';
  static const String _logHeader = 'GameSaveLocalDatasource';

  final SharedPreferencesWithCache _preferences;
  final Logger _logger;

  const GameSaveLocalDatasourceImpl({required this._preferences, required this._logger});

  @override
  SaveDBO? load() {
    final raw = _preferences.getString(_key);
    if (raw == null) return null;
    return SaveDBO.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  void save(SaveDBO save) {
    unawaited(_preferences.setString(_key, jsonEncode(save.toJson())).catchError(_logFailure));
  }

  @override
  void clear() {
    unawaited(_preferences.remove(_key).catchError(_logFailure));
  }

  void _logFailure(Object error, StackTrace stackTrace) {
    _logger.error(message: '$error', header: _logHeader, stackTrace: stackTrace);
  }
}
