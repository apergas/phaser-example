import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/types.dart';

base class FailingPreferencesFake extends InMemorySharedPreferencesAsync {
  FailingPreferencesFake({required this.error}) : super.empty();

  final Object error;

  @override
  Future<bool> setString(String key, String value, SharedPreferencesOptions options) async {
    throw error;
  }

  @override
  Future<bool> clear(ClearPreferencesParameters parameters, SharedPreferencesOptions options) async {
    throw error;
  }
}
