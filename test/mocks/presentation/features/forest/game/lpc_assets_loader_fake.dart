import 'package:rpg/layers/presentation/features/forest/game/atlas/lpc_assets.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/lpc_assets_loader.dart';

class LpcAssetsLoaderFake implements LpcAssetsLoader {
  LpcAssetsLoaderFake(this.assets);

  final LpcAssets assets;
  bool loadCalled = false;

  @override
  Future<LpcAssets> load() async {
    loadCalled = true;
    return assets;
  }
}
