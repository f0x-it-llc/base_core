import 'package:clean_signals/clean_signals.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../failures/app_failure.dart';

/// Renders a signals [AsyncState] with three branches:
///
/// - data — delegates to [builder]; if a reload is in flight the stale data
///   stays visible under a thin progress bar (no blanking on refresh),
/// - error (no data) — user-facing message + optional retry button,
/// - loading — centered spinner.
///
/// Read the state inside a [SignalBuilder] so the view rebuilds:
///
/// ```dart
/// SignalBuilder(builder: (_) => AsyncView(
///   state: controller.members.value,
///   onRetry: controller.load,
///   builder: (members) => ListView(...),
/// ))
/// ```
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
  });

  final AsyncState<T> state;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.hasValue) {
      final content = builder(state.requireValue);
      if (!state.isLoading) return content;
      return Stack(
        children: [
          content,
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
        ],
      );
    }

    if (state.hasError) {
      final error = state.error;
      final message =
          error is Failure ? error.userMessage : 'Something went wrong.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off,
                  size: 40, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }
}
