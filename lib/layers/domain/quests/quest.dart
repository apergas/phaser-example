import '../../../core/config/constants/enum/quest_id.dart';
import '../../../core/config/constants/enum/quest_line.dart';
import '../world/world.dart';

abstract interface class Quest {
  QuestId get id;

  QuestLine get line;

  int get target;

  int progress(World world);
}
