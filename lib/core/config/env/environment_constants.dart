import '../di/di_environment.dart';

class EnvironmentConstants {
  static const String diEnvironment = String.fromEnvironment('DI_ENVIRONMENT', defaultValue: DiEnvironment.dev);
}
