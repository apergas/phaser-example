import '../di/di_environment.dart';

class EnvironmentConstants {
  static const String name = String.fromEnvironment('ENVIRONMENT_NAME', defaultValue: 'DEV');
  static const String diEnvironment = String.fromEnvironment('DI_ENVIRONMENT', defaultValue: DiEnvironment.dev);
}
