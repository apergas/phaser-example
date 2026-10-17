import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class StorageModule {
  @singleton
  @preResolve
  Future<SharedPreferencesWithCache> get preferences =>
      SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
}
