import 'dart:async';

import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:signals/signals.dart';

import 'activity.dart';
import 'failure.dart';
import 'logging.dart';
import 'result.dart';
import 'retry.dart';
import 'usecase.dart';

/// Base class for presentation-layer controllers (view models).
///
/// A controller owns a feature's reactive state as signals and executes use
/// cases through [run] / [runInto] / [watch], which provide:
///
/// - ref-counted [isLoading] across overlapping operations,
/// - a broadcast [failures] stream for global error handling (snackbars,
///   logging, analytics),
/// - per-call [RetryPolicy] retries,
/// - lifecycle cleanup: everything registered with [onDispose], created with
///   [autoEffect], or subscribed with [watch] is torn down by [dispose].
///
/// ```dart
/// class UsersController extends Controller {
///   UsersController(this._getUsers);
///
///   final GetUsers _getUsers;
///
///   final users = asyncStateSignal<List<User>>();
///
///   Future<void> load() =>
///       runInto(_getUsers, noParams, into: users,
///           retry: const RetryPolicy(maxAttempts: 3));
/// }
/// ```
abstract class Controller {
  Controller() {
    logger.d('$runtimeType init');
  }

  @protected
  Logger get logger => CleanSignalsLogger.instance.logger;

  final ActivityTracker _activity = ActivityTracker();
  final StreamController<Failure> _failures = StreamController.broadcast();
  final List<FutureOr<void> Function()> _disposers = [];
  bool _disposed = false;

  /// Whether at least one operation started by [run]/[runInto] is in flight.
  ReadonlySignal<bool> get isLoading => _activity.isLoading;

  /// Every failure produced by [run], [runInto] and [watch] (after retries
  /// are exhausted). Subscribe once near the UI root of the feature to show
  /// snackbars or report errors.
  Stream<Failure> get failures => _failures.stream;

  /// Registers [cleanup] to run when the controller is disposed.
  /// Cleanups run in reverse registration order.
  @protected
  void onDispose(FutureOr<void> Function() cleanup) {
    _disposers.add(cleanup);
  }

  /// Creates a signals [effect] whose cleanup is bound to [dispose].
  @protected
  EffectCleanup autoEffect(dynamic Function() fn) {
    final cleanup = effect(fn);
    onDispose(cleanup);
    return cleanup;
  }

  /// Executes [useCase] with [params], returning its [Result].
  ///
  /// While running, [isLoading] is `true` (disable with
  /// `trackActivity: false` for background work). If the final outcome is a
  /// [Failed], the failure is emitted on [failures] (disable with
  /// `emitFailure: false` when handling the failure locally).
  ///
  /// With a [retry] policy, failed attempts whose failure satisfies
  /// `retry.shouldRetry` are re-executed up to `retry.maxAttempts` total
  /// attempts, with exponential backoff between them. Only the final failure
  /// is emitted.
  @protected
  Future<Result<R>> run<P, R>(
    UseCase<P, R> useCase,
    P params, {
    RetryPolicy retry = RetryPolicy.none,
    bool trackActivity = true,
    bool emitFailure = true,
  }) async {
    Future<Result<R>> attempt() => _runWithRetry(useCase, params, retry);

    final result =
        await (trackActivity ? _activity.track(attempt) : attempt());

    if (result case Failed(:final failure) when emitFailure) {
      _emitFailure(failure);
    }
    return result;
  }

  /// Like [run], but additionally drives a `Signal<AsyncState<R>>` through
  /// the operation's lifecycle:
  ///
  /// - before running: [AsyncDataReloading] if [into] already holds data
  ///   (existing content stays visible during the refresh), otherwise
  ///   [AsyncLoading];
  /// - after running: [AsyncData] on success, [AsyncError] on failure.
  @protected
  Future<Result<R>> runInto<P, R>(
    UseCase<P, R> useCase,
    P params, {
    required Signal<AsyncState<R>> into,
    RetryPolicy retry = RetryPolicy.none,
    bool trackActivity = true,
    bool emitFailure = true,
  }) async {
    final current = into.value;
    into.value = current.hasValue
        ? AsyncState.dataReloading(current.requireValue)
        : AsyncState.loading();

    final result = await run(
      useCase,
      params,
      retry: retry,
      trackActivity: trackActivity,
      emitFailure: emitFailure,
    );

    if (!_disposed) into.value = result.toAsyncState();
    return result;
  }

  /// Subscribes to [useCase], routing successes to [onData] and failures to
  /// [onFailure] and (unless `emitFailures: false`) the [failures] stream.
  ///
  /// The subscription is cancelled automatically on [dispose]; cancel the
  /// returned subscription earlier if the stream should stop sooner.
  @protected
  StreamSubscription<Result<R>> watch<P, R>(
    StreamUseCase<P, R> useCase,
    P params, {
    required void Function(R value) onData,
    void Function(Failure failure)? onFailure,
    bool emitFailures = true,
  }) {
    final subscription = useCase(params).listen((result) {
      switch (result) {
        case Success(:final value):
          onData(value);
        case Failed(:final failure):
          onFailure?.call(failure);
          if (emitFailures) _emitFailure(failure);
      }
    });
    onDispose(subscription.cancel);
    return subscription;
  }

  Future<Result<R>> _runWithRetry<P, R>(
    UseCase<P, R> useCase,
    P params,
    RetryPolicy retry,
  ) async {
    var attemptNumber = 1;
    while (true) {
      final result = await useCase(params);
      switch (result) {
        case Success():
          return result;
        case Failed(:final failure):
          final retriesLeft = attemptNumber < retry.maxAttempts;
          if (!retriesLeft || !retry.shouldRetry(failure)) return result;
          final wait = retry.delayFor(attemptNumber);
          logger.d(
            '${useCase.runtimeType} failed ($failure) — retrying '
            '${attemptNumber + 1}/${retry.maxAttempts} in $wait',
          );
          await Future<void>.delayed(wait);
          attemptNumber++;
      }
    }
  }

  void _emitFailure(Failure failure) {
    logger.w('$runtimeType failure: $failure',
        error: failure.cause, stackTrace: failure.stackTrace);
    if (!_disposed && !_failures.isClosed) _failures.add(failure);
  }

  /// Releases everything owned by the controller. Safe to call twice.
  @mustCallSuper
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    logger.d('$runtimeType dispose');
    for (final cleanup in _disposers.reversed) {
      cleanup();
    }
    _disposers.clear();
    _failures.close();
    _activity.dispose();
  }
}
