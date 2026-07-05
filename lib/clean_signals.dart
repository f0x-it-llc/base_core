/// A lightweight use-case and controller framework for signals-based Flutter
/// and Dart applications.
///
/// - [Result] / [Success] / [Failed] — typed operation outcomes
/// - [Failure] — sealed-hierarchy-friendly domain failures
/// - [UseCase] / [StreamUseCase] — guarded business-logic units
/// - [Controller] — signals-based view-model base with activity tracking,
///   failure routing, retries and lifecycle cleanup
/// - [ActivityTracker] — ref-counted loading state
/// - [RetryPolicy] — per-call declarative retries
library;

export 'src/activity.dart';
export 'src/controller.dart';
export 'src/failure.dart';
export 'src/logging.dart';
export 'src/result.dart';
export 'src/retry.dart';
export 'src/usecase.dart';
