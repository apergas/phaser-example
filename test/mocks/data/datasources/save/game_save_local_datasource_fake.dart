import 'package:farming/layers/data/datasources/save/local/dbo/save_dbo.dart';
import 'package:farming/layers/data/datasources/save/source/game_save_local_datasource.dart';

class GameSaveLocalDatasourceFake implements GameSaveLocalDatasource {
  SaveDBO? stored;
  Object? loadError;
  Object? saveError;
  Object? clearError;
  int loadCalls = 0;
  final List<SaveDBO> saved = [];
  int clearCalls = 0;

  @override
  SaveDBO? load() {
    loadCalls++;
    final error = loadError;
    if (error != null) throw error;
    return stored;
  }

  @override
  void save(SaveDBO save) {
    final error = saveError;
    if (error != null) throw error;
    saved.add(save);
    stored = save;
  }

  @override
  void clear() {
    clearCalls++;
    final error = clearError;
    if (error != null) throw error;
    stored = null;
  }
}
