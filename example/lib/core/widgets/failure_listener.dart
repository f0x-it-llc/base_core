import 'dart:async';

import 'package:base_core/base_core.dart';
import 'package:flutter/material.dart';

import '../failures/app_failure.dart';

/// Subscribes to a controller's [Controller.failures] stream and surfaces
/// each failure as a snackbar. Mount once per screen, above the content:
///
/// ```dart
/// FailureListener(failures: controller.failures, child: ...)
/// ```
class FailureListener extends StatefulWidget {
  const FailureListener({
    super.key,
    required this.failures,
    required this.child,
  });

  final Stream<Failure> failures;
  final Widget child;

  @override
  State<FailureListener> createState() => _FailureListenerState();
}

class _FailureListenerState extends State<FailureListener> {
  StreamSubscription<Failure>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.failures.listen(_show);
  }

  void _show(Failure failure) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failure.userMessage)),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
