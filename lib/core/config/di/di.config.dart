// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:rpg/core/error-handling/handlers/app_exception_handler.dart'
    as _i216;
import 'package:rpg/core/services/logging/bloc/bloc_logger.dart' as _i685;
import 'package:rpg/core/services/logging/hybrid-logger/custom_logger_impl.dart'
    as _i540;
import 'package:rpg/core/services/logging/source/logger.dart' as _i879;
import 'package:rpg/core/services/navigation/navify/navify_impl.dart' as _i192;
import 'package:rpg/core/services/navigation/source/navigation_service.dart'
    as _i100;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.factory<_i216.AppExceptionHandler>(() => _i216.AppExceptionHandler());
    gh.singleton<_i879.Logger>(() => _i540.CustomLoggerImpl());
    gh.singleton<_i100.NavigationService>(() => _i192.NavifyImpl());
    gh.singleton<_i685.BlocLogger>(
      () => _i685.BlocLogger(logger: gh<_i879.Logger>()),
    );
    return this;
  }
}
