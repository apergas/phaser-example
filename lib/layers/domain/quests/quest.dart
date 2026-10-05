import '../../../core/config/constants/enum/quest_id.dart';
import '../world/world.dart';

abstract interface class Quest {
  QuestId get id;

  int get target;

  int progress(World world);
}
