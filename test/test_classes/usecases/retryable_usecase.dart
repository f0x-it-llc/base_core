import 'package:base_core/base_core.dart';
import 'package:dartz/dartz.dart';

import '../user_model.dart';

class NetworkFailure extends RetryableFailure {
  NetworkFailure(dynamic params, Type runtimeType)
      : super(
          params: params,
          useCase: runtimeType,
          delay: Duration(milliseconds: 1500),
        );
}

class RetryableUseCase extends UseCase<bool, User> {
  @override
  Future<Either<Failure, User>> execute(bool params) async {
    final shouldFail = params;

    logger.i('RetryableUseCase execute with params $params');

    if (shouldFail) {
      return left(
        NetworkFailure(params, this.runtimeType),
      );
    }
    return right(User(1, 'John', 'Doe', 'Hello, world!', 25));
  }
}
