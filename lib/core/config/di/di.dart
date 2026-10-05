import 'package:injectable/injectable.dart';

import 'di.config.dart';
import 'locator.dart';

@InjectableInit()
Future<void> configureDependencies({required String environment}) async {
  locator.init(environment: environment);
}
