import 'package:flame/cache.dart';
import 'package:flutter/services.dart';

import 'alpha_mask.dart';
import 'lpc_assets.dart';
import 'lpc_atlas.dart';

class LpcAssetsLoader {
  static const String prefix = 'lib/core/assets/images/';
  static const String atlasPath = 'lpc/forest.json';

  final AssetBundle _bundle;

  LpcAssetsLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  Future<LpcAssets> load() async {
    final images = Images(prefix: prefix, bundle: _bundle);
    final forest = await images.load('lpc/forest.png');
    final atlasSource = await _bundle.loadString('$prefix$atlasPath');
    return LpcAssets(
      forest: forest,
      frames: LpcAtlas.parse(atlasSource),
      forestMask: await AlphaMask.fromImage(forest),
      ground: await images.load('lpc/ground.png'),
      heroWalk: await images.load('lpc/hero-walk.png'),
      heroIdle: await images.load('lpc/hero-idle.png'),
      heroWalkAxe: await images.load('lpc/hero-walk-axe.png'),
      heroIdleAxe: await images.load('lpc/hero-idle-axe.png'),
      heroChop: await images.load('lpc/hero-chop.png'),
      heroHammer: await images.load('lpc/hero-hammer.png'),
    );
  }
}
