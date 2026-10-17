import 'package:injectable/injectable.dart';

import 'di.config.dart';
import 'locator.dart';

@InjectableInit()
Future<void> configureDependencies({required String environment}) async {
  await locator.init(environment: environment);
}
