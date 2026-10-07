import 'package:flame/cache.dart';
import 'package:flutter/services.dart';

import '../../../forest/game/atlas/lpc_assets_loader.dart';
import '../../../forest/game/atlas/lpc_atlas.dart';
import 'arena_assets.dart';

class ArenaAssetsLoader {
  static const String prefix = LpcAssetsLoader.prefix;
  static const String atlasPath = 'lpc/arena.json';
  static const String imagePath = 'lpc/arena.png';

  final AssetBundle _bundle;

  ArenaAssetsLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  Future<ArenaAssets> load() async {
    final images = Images(prefix: prefix, bundle: _bundle);
    final atlas = await images.load(imagePath);
    final atlasSource = await _bundle.loadString('$prefix$atlasPath');
    return ArenaAssets(atlas: atlas, frames: LpcAtlas.parse(atlasSource));
  }
}
