import 'dart:async';

import 'package:logger/logger.dart';
import 'package:meta/meta.dart';

import 'failure.dart';
import 'logging.dart';
import 'result.dart';

/// Parameter type for use cases that take no input.
///
/// ```dart
/// class GetUsers extends UseCase<NoParams, List<User>> { ... }
///
/// final result = await getUsers(noParams);
/// ```
final class NoParams {
  const NoParams();
}

const noParams = NoParams();

/// A single unit of business logic producing one [Result].
///
/// Implement [execute] with the happy path. Domain failures can be returned
/// (`return Failed(NotFoundFailure(...))`) or thrown (`throw
/// NetworkFailure(...)`) — [call] catches thrown [Failure]s and converts any
/// other uncaught error into an [UnexpectedFailure], so callers always get a
/// [Result] and never an exception.
///
/// ```dart
/// class GetUser extends UseCase<String, User> {
///   GetUser(this._repository);
///
///   final UserRepository _repository;
///
///   @override
///   Future<Result<User>> execute(String userId) async {
///     return Success(await _repository.getUser(userId));
///   }
/// }
/// ```
abstract class UseCase<P, R> {
  /// Logger shared through [BaseCoreLogger]; available to subclasses.
  @protected
  Logger get logger => BaseCoreLogger.instance.logger;

  /// The business logic. Prefer calling the use case via [call] so errors
  /// are converted to [Failed] results.
  @protected
  Future<Result<R>> execute(P params);

  /// Executes the use case, guaranteeing a [Result] is returned.
  Future<Result<R>> call(P params) async {
    try {
      return await execute(params);
    } on Failure catch (failure) {
      return Failed(failure);
    } catch (error, stackTrace) {
      logger.e(
        'Unhandled error in $runtimeType',
        error: error,
        stackTrace: stackTrace,
      );
      return Failed(UnexpectedFailure(
        message: 'Unhandled error in $runtimeType',
        cause: error,
        stackTrace: stackTrace,
      ));
    }
  }
}

/// A unit of business logic producing a stream of [Result]s.
///
/// Like [UseCase], errors raised by the underlying stream are converted into
/// [Failed] events instead of propagating as stream errors. If the source
/// survives the error (e.g. a broadcast stream) it keeps emitting; if the
/// error terminated the source, the [Failed] event is the last one.
abstract class StreamUseCase<P, R> {
  /// Logger shared through [BaseCoreLogger]; available to subclasses.
  @protected
  Logger get logger => BaseCoreLogger.instance.logger;

  /// The business logic. Prefer consuming the use case via [call].
  @protected
  Stream<Result<R>> execute(P params);

  /// Subscribes to the use case, guaranteeing an error-free result stream.
  ///
  /// Implemented with a transformer rather than an `async*` wrapper so that
  /// cancelling the subscription propagates to the source immediately (an
  /// `async*` generator blocked on a slow source would delay cancellation
  /// until the source's next event).
  Stream<Result<R>> call(P params) {
    final Stream<Result<R>> source;
    try {
      source = execute(params);
    } on Failure catch (failure) {
      return Stream.value(Failed(failure));
    } catch (error, stackTrace) {
      return Stream.value(Failed(_unexpected(error, stackTrace)));
    }
    return source.transform(
      StreamTransformer.fromHandlers(
        handleError: (error, stackTrace, sink) {
          sink.add(Failed(
            error is Failure ? error : _unexpected(error, stackTrace),
          ));
        },
      ),
    );
  }

  Failure _unexpected(Object error, StackTrace stackTrace) {
    logger.e(
      'Unhandled error in $runtimeType',
      error: error,
      stackTrace: stackTrace,
    );
    return UnexpectedFailure(
      message: 'Unhandled error in $runtimeType',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
