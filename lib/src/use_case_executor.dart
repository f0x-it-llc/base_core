import 'dart:async';

import 'package:base_core/base_core.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

extension<T> on Stream<T> {
  Stream<T> optionalAsyncMap(AsyncMapFn<T>? fn) {
    if (fn != null) {
      return this.asyncMap(fn);
    } else {
      return this;
    }
  }

  Stream<T> optionalMap(MapStreamFn<T>? fn) {
    if (fn != null) {
      return this.switchMap(fn);
    } else {
      return this;
    }
  }

  Stream<T> optionallyNotifyListeners(
    ObserverList<DataListener<T>>? listeners,
  ) {
    if (listeners != null && listeners.isNotEmpty) {
      return this.doOnData((event) {
        listeners.forEach((fn) => fn(event));
      });
    } else {
      return this;
    }
  }
}

class UseCaseExecutor<D> {
  final PublishSubject<
      Tuple2<Trampoline<Stream<Either<Failure, dynamic>>>,
          UseCaseMapFn<D, dynamic>?>> _runUseCase = PublishSubject();

  final ActivityIndicator activityIndicator;
  final PublishSubject<Failure> _onFailure;
  final BehaviorSubject<D> rx;
  final Logger logger;
  final Function() _onDone;
  final ObserverList<DataListener<D>> _listeners;
  AsyncMapFn<D>? asyncMapFn;
  MapStreamFn<D>? mapStreamFn;

  UseCaseExecutor(
    this.activityIndicator,
    this._onFailure,
    this.rx,
    this.logger,
    this._onDone,
    this._listeners,
    this.asyncMapFn,
    this.mapStreamFn,
  );

  StreamSubscription<D> get subscription => _runUseCase
      .whereNotLoading(activityIndicator)
      .switchMap((t) => t.value1
          .run()
          .map((e) => e.map((d) => d is D ? d : t.value2!.call(rx.value!, d)))
          .trackActivity(activityIndicator)
          .onFailureForwardTo(_onFailure)
          .optionalAsyncMap(asyncMapFn)
          .optionalMap(mapStreamFn)
          .optionallyNotifyListeners(_listeners)
          .doOnDone(_onDone))
      .listen(rx.add);

  void runUseCase<U, P>(
    U useCase,
    P params,
    UseCaseMapFn<D, dynamic>? mapFn,
  ) {
    Trampoline<Stream<Either<Failure, dynamic>>> runningUseCase;

    logger.t('runUseCase $U with params $params');

    if (useCase is DataManagerUseCase) {
      runningUseCase = (useCase as DataManagerUseCase<P, D>).tStream(
        tuple2<P, D>(params, rx.value),
      );
    } else if (useCase is UseCase) {
      runningUseCase = useCase.tStream(params);
    } else {
      logger.e('Invalid use case type: ${useCase.runtimeType}');
      throw ArgumentError('Invalid use case type: ${useCase.runtimeType}');
    }
    _runUseCase.add(tuple2(runningUseCase, mapFn));
  }

  void dispose() {
    _runUseCase.close();
  }
}
