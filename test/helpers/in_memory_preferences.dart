import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void useInMemoryPreferences() {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
}
