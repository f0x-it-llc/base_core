import 'dart:async';

import 'package:base_core/base_core.dart';
import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

class StreamingUseCaseManager<D> {
  final Map<StreamingUseCase, StreamSubscription<D>> _runningUseCases = {};
  final CompositeSubscription _compositeSubscription;
  final PublishSubject<Failure> _onFailure;
  final BehaviorSubject<D> rx;
  final Logger logger;

  StreamingUseCaseManager(
    this._compositeSubscription,
    this._onFailure,
    this.rx,
    this.logger,
  );

  void register<U, P>(
    StreamingUseCase useCase,
    P params,
    UseCaseMapFn<D, dynamic>? mapFn,
  ) {
    if (_runningUseCases.containsKey(useCase)) {
      logger.w('Cannot register same stream twice');
      return;
    }

    final ss = useCase(useCase is DataManagerStreamingUseCase
            ? tuple2<P, BehaviorSubject<D>>(params, rx)
            : params)
        .onFailureForwardTo(_onFailure)
        .map((d) => d is D ? d : mapFn!.call(rx.value, d))
        .listen(_updateValue);

    _compositeSubscription.add(ss);
    _runningUseCases[useCase] = ss;
  }

  void deregister<U>(StreamingUseCase useCase) {
    final ss = _runningUseCases[useCase];
    if (ss != null) {
      _compositeSubscription.remove(ss);
      _runningUseCases.remove(useCase);
    }
  }

  void _updateValue(D data) => rx.add(data);
}
