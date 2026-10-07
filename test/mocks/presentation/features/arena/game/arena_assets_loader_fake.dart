import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_assets.dart';
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_assets_loader.dart';

class ArenaAssetsLoaderFake implements ArenaAssetsLoader {
  ArenaAssetsLoaderFake(this.assets);

  final ArenaAssets assets;
  bool loadCalled = false;

  @override
  Future<ArenaAssets> load() async {
    loadCalled = true;
    return assets;
  }
}
