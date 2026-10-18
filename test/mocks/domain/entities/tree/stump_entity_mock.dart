import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/tree/stump_entity.dart';

abstract final class StumpEntityMock {
  static const PositionEntity site = PositionEntity(x: 200, y: 100);

  static const StumpEntity fresh = StumpEntity(id: 'tree-1', kind: TreeKind.pine, position: site);

  static const StumpEntity freshOak = StumpEntity(id: 'tree-1', kind: TreeKind.oak, position: site);

  static const StumpEntity almostSapling = StumpEntity(
    id: 'tree-1',
    kind: TreeKind.pine,
    position: site,
    elapsedMs: 59999,
  );

  static const StumpEntity sapling = StumpEntity(id: 'tree-1', kind: TreeKind.pine, position: site, elapsedMs: 60000);

  static const StumpEntity almostReady = StumpEntity(
    id: 'tree-1',
    kind: TreeKind.pine,
    position: site,
    elapsedMs: 179950,
  );

  static const StumpEntity ready = StumpEntity(id: 'tree-1', kind: TreeKind.pine, position: site, elapsedMs: 180000);

  static const StumpEntity otherId = StumpEntity(id: 'tree-2', kind: TreeKind.pine, position: site);

  static const StumpEntity elsewhereAlmostSapling = StumpEntity(
    id: 'tree-2',
    kind: TreeKind.pine,
    position: PositionEntity(x: 200, y: 300),
    elapsedMs: 59999,
  );
}
