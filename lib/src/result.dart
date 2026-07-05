import 'package:signals/signals.dart';

import 'failure.dart';

/// The outcome of an operation: either [Success] with a value or [Failed]
/// with a [Failure].
///
/// Being sealed, results can be destructured exhaustively:
///
/// ```dart
/// switch (result) {
///   case Success(:final value):
///     print('got $value');
///   case Failed(:final failure):
///     print('failed: $failure');
/// }
/// ```
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = Failed<T>;

  /// Runs [body] and captures its outcome, converting thrown [Failure]s and
  /// unexpected errors into a [Failed] result.
  static Future<Result<T>> guard<T>(Future<T> Function() body) async {
    try {
      return Success(await body());
    } on Failure catch (failure) {
      return Failed(failure);
    } catch (error, stackTrace) {
      return Failed(UnexpectedFailure(cause: error, stackTrace: stackTrace));
    }
  }

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failed<T>;

  /// The value if this is a [Success], otherwise `null`.
  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Failed() => null,
      };

  /// The failure if this is a [Failed], otherwise `null`.
  Failure? get failureOrNull => switch (this) {
        Success() => null,
        Failed(:final failure) => failure,
      };

  /// The value if this is a [Success]; throws the [Failure] otherwise.
  T get requireValue => switch (this) {
        Success(:final value) => value,
        Failed(:final failure) => throw failure,
      };

  /// Collapses both branches into a single value.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      switch (this) {
        Success(:final value) => onSuccess(value),
        Failed(:final failure) => onFailure(failure),
      };

  /// Transforms the success value, passing failures through unchanged.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success(:final value) => Success(transform(value)),
        Failed(:final failure) => Failed(failure),
      };

  /// Chains a result-producing operation, passing failures through unchanged.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) =>
      switch (this) {
        Success(:final value) => transform(value),
        Failed(:final failure) => Failed(failure),
      };

  /// The value if this is a [Success], otherwise the result of [orElse].
  T getOrElse(T Function(Failure failure) orElse) => switch (this) {
        Success(:final value) => value,
        Failed(:final failure) => orElse(failure),
      };

  /// Converts this result into a signals [AsyncState].
  ///
  /// [Success] maps to [AsyncData]; [Failed] maps to [AsyncError] carrying
  /// the [Failure] as its error. Useful for storing results in
  /// `Signal<AsyncState<T>>` state consumed by `Watch` widgets.
  AsyncState<T> toAsyncState() => switch (this) {
        Success(:final value) => AsyncState.data(value),
        Failed(:final failure) =>
          AsyncState.error(failure, failure.stackTrace),
      };
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Success, value);

  @override
  String toString() => 'Success<$T>($value)';
}

final class Failed<T> extends Result<T> {
  const Failed(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Failed<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Failed, failure);

  @override
  String toString() => 'Failed<$T>($failure)';
}

/// Creates a `Signal<AsyncState<T>>` seeded with [AsyncLoading].
///
/// The conventional shape for controller state fed by [Result]-returning use
/// cases:
///
/// ```dart
/// final users = asyncStateSignal<List<User>>();
/// ```
Signal<AsyncState<T>> asyncStateSignal<T>() =>
    signal<AsyncState<T>>(AsyncState<T>.loading());
