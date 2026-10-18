import '../local/dbo/save_dbo.dart';

abstract interface class GameSaveLocalDatasource {
  SaveDBO? load();

  void save(SaveDBO save);

  void clear();
}
