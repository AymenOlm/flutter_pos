import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_pos/core/logging/app_logger.dart';

class AppBlocObserver extends BlocObserver {
  AppBlocObserver(this._logger);

  final AppLogger _logger;

  @override
  void onEvent(Bloc bloc, Object? event) {
    _logger.debug(
      feature: 'bloc',
      action: 'event',
      outcome: 'received',
      context: <String, Object?>{
        'bloc': bloc.runtimeType.toString(),
        'event': event.runtimeType.toString(),
      },
    );
    super.onEvent(bloc, event);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    _logger.debug(
      feature: 'bloc',
      action: 'transition',
      outcome: 'state_change',
      context: <String, Object?>{
        'bloc': bloc.runtimeType.toString(),
        'event': transition.event.runtimeType.toString(),
        'currentState': transition.currentState.runtimeType.toString(),
        'nextState': transition.nextState.runtimeType.toString(),
      },
    );
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    _logger.error(
      feature: 'bloc',
      action: 'error',
      outcome: 'failed',
      errorCode: 'BLOC_UNCAUGHT',
      context: <String, Object?>{'bloc': bloc.runtimeType.toString()},
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}
