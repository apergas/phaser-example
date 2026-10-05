import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../source/logger.dart';

@Singleton()
class BlocLogger extends BlocObserver {
  final Logger _logger;

  const BlocLogger({required this._logger});

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    _logger.error(message: error.toString(), stackTrace: stackTrace, header: 'Bloc Error');
    super.onError(bloc, error, stackTrace);
  }
}
