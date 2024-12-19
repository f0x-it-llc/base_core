import 'dart:async';

import 'package:base_core/base_core.dart';
import 'package:base_core/src/streaming_use_case_manager.dart';
import 'package:base_core/src/use_case_executor.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

typedef DataListener<T> = void Function(T);
typedef AsyncMapFn<T> = FutureOr<T> Function(T);
typedef MapStreamFn<T> = Stream<T> Function(T);

typedef UseCaseMapFn<D, P> = D Function(D, P);
typedef StreamingUseCaseMapFn<D, P> = D Function(D, P);

/// A generic data manager that handles state management and use case execution
///
/// Type Parameters:
/// * [D] - The type of data being managed. Must be non-nullable.
abstract class DataManager<D> {
  @protected
  late final Logger logger;

  late final UseCaseExecutor<D> _useCaseExecutor;
  late final StreamingUseCaseManager<D> _streamingManager;
  late final PublishSubject<Failure> _onFailure;
  late final ActivityIndicator _activityIndicator;
  late final CompositeSubscription compositeSubscription;

  int maxRetries;

  /// Creates a new DataManager instance
  ///
  /// Parameters:
  /// * [useCaseGen] - Generator containing all available use cases
  /// * [initData] - Optional initial data value
  /// * [autoClearFns] - Whether to clear async functions after execution
  ///
  /// Throws:
  /// * [ArgumentError] if [useCaseGen] is null
  DataManager(
    UseCaseGenerator<D> useCaseGen, {
    D? initData,
    this.autoClearFns = true,
    this.maxRetries = 3,
  })  : rx = initData != null
            ? BehaviorSubject<D>.seeded(initData)
            : BehaviorSubject<D>(),
        useCases = useCaseGen.useCases,
        streamingUseCases = useCaseGen.streamingUseCases {
    logger = BaseCoreLogger.instance.logger;
    _onFailure = PublishSubject<Failure>();
    _activityIndicator = ActivityIndicator();

    _useCaseExecutor = UseCaseExecutor(
      _activityIndicator,
      _onFailure,
      rx,
      logger,
      _handleOnDone,
      _listeners,
      asyncMapFn,
      mapStreamFn,
    );
  }

  final bool autoClearFns;

  final _runUseCase = PublishSubject<
      Tuple2<Trampoline<Stream<Either<Failure, dynamic>>>,
          UseCaseMapFn<D, dynamic>?>>();
  final onDone = PublishSubject();

  Future<void> get waitDone => onDone.first;
  ObserverList<DataListener<D>> _listeners = ObserverList<DataListener<D>>();

  AsyncMapFn<D>? asyncMapFn;
  MapStreamFn<D>? mapStreamFn;

  void registerSubscription(CompositeSubscription subscription) {
    logger.t('registerSubscription');
    compositeSubscription = subscription;
    _useCaseExecutor.subscription.addTo(compositeSubscription);

    _streamingManager = StreamingUseCaseManager(
      compositeSubscription,
      _onFailure,
      rx,
      logger,
    );

    _setupRetryMechanism();
  }

  final BehaviorSubject<D> rx;
  Stream<D> get stream => rx.stream;
  D get value => rx.value;
  D? get valueOrNull => rx.valueOrNull;

  final Map<Type, Tuple2<UseCase<dynamic, dynamic>, UseCaseMapFn<D, dynamic>?>>
      useCases;

  final Map<Type,
          Tuple2<StreamingUseCase<dynamic, dynamic>, UseCaseMapFn<D, dynamic>?>>
      streamingUseCases;

  Stream<bool> get isLoading => _activityIndicator.stream;
  Stream<Failure> get onFailure => _onFailure.stream;

  void _handleOnDone() {
    if (autoClearFns) {
      asyncMapFn = null;
      mapStreamFn = null;
    }
    onDone.add(null);
  }

  /// Sets up automatic retry mechanism for failed operations
  void _setupRetryMechanism() {
    var retryCount = 0;
    _onFailure
        .where((failure) => failure is RetryableFailure)
        .asyncMap((failure) async {
      await Future.delayed((failure as RetryableFailure).delay);
      return failure;
    }).listen((failure) {
      final tuple = useCases[failure.useCase];
      var useCase = tuple?.value1;
      _retry() {
        logger.d('RetryableFailure: ${failure}, ${retryCount}');
        if (retryCount < maxRetries) {
          retryCount++;
          logger.t('Retrying operation (${retryCount}/${maxRetries})');
          // Re-run the last use case

          // Get the use case from the stored type

          if (tuple != null) {
            useCase = tuple.value1;
            final mapFn = tuple.value2;

            // Execute the use case directly through the executor
            _useCaseExecutor.runUseCase(
              useCase,
              failure.params,
              mapFn,
            );
          }
        } else {
          logger.d('Max retries reached for use case ${useCase}');
          retryCount = 0;
        }
      }

      _retry();
    });
  }

  /// Runs a use case with validation and error handling
  ///
  /// Type Parameters:
  /// * [U] - The type of use case to run
  /// * [P] - The type of parameters for the use case
  ///
  /// Throws:
  /// * [StateError] if the use case is not registered
  /// * [ArgumentError] if required parameters are missing
  void runUseCase<U, P>(P params) {
    final tuple = useCases[U];
    if (tuple == null) {
      throw StateError('UseCase of type $U not registered');
    }

    final useCase = tuple.value1;
    final mapFn = tuple.value2;

    try {
      _validateParams<U, P>(params);
      _useCaseExecutor.runUseCase(useCase, params, mapFn);
    } catch (e, stack) {
      logger.e('Error running use case', error: e, stackTrace: stack);
      _onFailure.add(UnexpectedFailure(e.toString()));
    }
  }

  /// Validates parameters for a specific use case
  void _validateParams<U, P>(P params) {
    if (params == null && !_isNullableParam<P>()) {
      throw ArgumentError('Non-nullable parameters required for UseCase $U');
    }
  }

  bool _isNullableParam<P>() {
    return null is P;
  }

  void dispose() {
    _useCaseExecutor.dispose();
    rx.close();
    _onFailure.close();
    _activityIndicator.close();
    compositeSubscription.dispose();
  }

  void registerStreamingUseCase<U, P>(P params) {
    final tuple = streamingUseCases[U];

    final useCase = tuple!.value1;
    final mapFn = tuple.value2;

    _streamingManager.register(useCase, params, mapFn);
  }

  void deRegisterUseCase<U>() {
    final tuple = streamingUseCases[U];
    final useCase = tuple!.value1;

    _streamingManager.deregister(useCase);
  }

  void update(D data) {
    rx.add(data);
  }

  void addListener(DataListener<D> listener) {
    _listeners.add(listener);
  }

  void removeListener(DataListener<D> listener) {
    _listeners.remove(listener);
  }

  @protected
  void close() {
    rx.close();
    _onFailure.close();
    _runUseCase.close();
    _activityIndicator.close();
  }
}
