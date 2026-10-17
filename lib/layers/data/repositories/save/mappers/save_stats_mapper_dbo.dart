import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/tree_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/game/stats_entity.dart';
import '../../../datasources/save/local/dbo/save_stats_dbo.dart';

@Injectable()
class SaveStatsMapperDBO {
  SaveStatsDBO toDBO(StatsEntity stats) {
    return SaveStatsDBO(
      treesFelled: stats.treesFelled,
      treesFelledByKind: {
        for (final MapEntry(key: kind, value: count) in stats.treesFelledByKind.entries) kind.name: count,
      },
      buildingsCompleted: stats.buildingsCompleted,
      treesRegrown: stats.treesRegrown,
    );
  }

  StatsEntity toEntity(SaveStatsDBO? dbo) {
    if (dbo == null) return const StatsEntity();
    return StatsEntity(
      treesFelled: _count(dbo.treesFelled, 'treesFelled'),
      treesFelledByKind: {
        for (final MapEntry(key: name, value: count) in (dbo.treesFelledByKind ?? const <String, int>{}).entries)
          TreeKind.values.asNameMap()[name] ?? (throw InvalidSaveException(data: 'stats: unknown tree kind "$name"')):
              _count(count, 'treesFelledByKind.$name'),
      },
      buildingsCompleted: _count(dbo.buildingsCompleted, 'buildingsCompleted'),
      treesRegrown: _count(dbo.treesRegrown, 'treesRegrown'),
    );
  }

  int _count(int? count, String field) {
    final value = count ?? 0;
    if (value < 0) throw InvalidSaveException(data: 'stats: $field $value');
    return value;
  }
}
