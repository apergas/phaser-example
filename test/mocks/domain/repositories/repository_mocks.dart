import 'package:mockito/annotations.dart';
import 'package:farming/layers/domain/repositories/level/level_repository.dart';
import 'package:farming/layers/domain/repositories/save/game_save_repository.dart';
import 'package:farming/layers/domain/repositories/session/game_session_repository.dart';

@GenerateMocks([LevelRepository, GameSessionRepository, GameSaveRepository])
void main() {}
