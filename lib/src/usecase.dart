import 'dart:async';

import 'package:base_core/base_core.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

abstract class StreamingUseCase<P, R> {
  @protected
  late Logger logger;

  StreamingUseCase() {
    logger = BaseCoreLogger.instance.logger;
  }

  Either<Failure, R> onError(Object object, StackTrace stackTrace);

  Stream<Either<Failure, R>> call(P param) =>
      run(param).onErrorReturnWith(onError);

  Stream<Either<Failure, R>> run(P param);
}

abstract class UseCase<P, R> {
  @protected
  late Logger logger;

  UseCase() {
    logger = BaseCoreLogger.instance.logger;
  }

  Future<Either<Failure, R>> execute(P params);

  Stream<Either<Failure, R>> call(P params) => execute(params).asStream();

  Trampoline<Stream<Either<Failure, R>>> tStream(P params) =>
      treturn(call(params));

  Future<B> result<B>(P params, B Function(Either<Failure, R>) onResult) async {
    final result = await execute(params);
    return onResult(result);
  }
}

// abstract class RetryableUseCase<P, R> extends UseCase<P, R> {
//   int retries = 0;
//   int maxRetries = 3;
//   Duration delay = Duration.zero;
// }

// A Usecase to be use inside a data manager

abstract class DataManagerUseCase<P, R> extends UseCase<Tuple2<P, R>, R> {
  late Tuple2<P, R> _params;

  @mustCallSuper
  void params(Tuple2<P, R> params) {
    _params = params;
  }

  P get param => _params.value1;
  R get value => _params.value2;
}

// abstract class DataManagerRetryableUseCase<P, R>
//     extends DataManagerUseCase<P, R> {
//   int retries = 0;
//   int maxRetries = 3;
//   Duration delay = Duration.zero;
// }

abstract class DataManagerStreamingUseCase<P, R>
    extends StreamingUseCase<Tuple2<P, BehaviorSubject<R>>, R> {
  late Tuple2<P, BehaviorSubject<R>> _params;

  @mustCallSuper
  void params(Tuple2<P, BehaviorSubject<R>> params) {
    _params = params;
  }

  P get param => _params.value1;
  BehaviorSubject<R> get value => _params.value2;
}
