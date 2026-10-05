import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AssetBundleFake extends AssetBundle {
  AssetBundleFake({required this.failingKey, this.isFailing = true});

  final String failingKey;
  bool isFailing;
  int failedLoads = 0;

  @override
  Future<ByteData> load(String key) async {
    if (isFailing && key == failingKey) {
      failedLoads++;
      throw FlutterError('Unable to load asset: "$key".');
    }
    return rootBundle.load(key);
  }

  @override
  Future<T> loadStructuredData<T>(String key, Future<T> Function(String value) parser) async =>
      parser(await loadString(key));
}
