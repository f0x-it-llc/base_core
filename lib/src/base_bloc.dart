import 'dart:async';

import 'package:base_core/base_core.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

typedef BlocBuilder<T> = T Function();
typedef BlocDisposer<T> = Function(T);

abstract class BaseBloc {
  @protected
  late Logger logger;

  BaseBloc() {
    logger = BaseCoreLogger.instance.logger;
    logger.d('init');
  }

  CompositeSubscription compositeSubscription = CompositeSubscription();

  void dispose() {
    logger.d('dispose');
    compositeSubscription.dispose();
  }
}

abstract class BaseState<T extends StatefulWidget> extends State<T> {
  late Logger logger;
  BaseState() {
    logger = BaseCoreLogger.instance.logger;
    logger.d('init');
  }

  CompositeSubscription compositeSubscription = CompositeSubscription();

  @override
  void dispose() {
    logger.d('dispose');
    compositeSubscription.dispose();
    super.dispose();
  }
}

class MultiBlocProvider extends StatelessWidget {
  final Widget child;

  final List<SingleBlocProvider<dynamic>> blocs;

  const MultiBlocProvider({
    Key? key,
    required this.blocs,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => blocs.reversed.fold(
        child,
        (previousValue, element) => element.makeBlocProvider(previousValue),
      );
}

class SingleBlocProvider<T extends BaseBloc> {
  final BlocBuilder<T> blocBuilder;
  final BlocDisposer<T>? blocDispose;

  SingleBlocProvider(this.blocBuilder, {this.blocDispose});

  BlocProvider<T> makeBlocProvider(Widget child) {
    return BlocProvider<T>(
      blocBuilder: blocBuilder,
      blocDisposer: blocDispose,
      child: child,
    );
  }
}

class BlocProvider<T extends BaseBloc> extends StatefulWidget {
  const BlocProvider({
    super.key,
    required this.child,
    required this.blocBuilder,
    this.blocDisposer,
  });

  final Widget child;
  final BlocBuilder<T> blocBuilder;
  final BlocDisposer<T>? blocDisposer;

  @override
  _BlocProviderState<T> createState() => _BlocProviderState<T>();

  static T? of<T extends BaseBloc>(BuildContext context) {
    final InheritedElement? inheritedElement = context
        .getElementForInheritedWidgetOfExactType<_BlocProviderInherited<T>>();
    if (inheritedElement == null) {
      return null;
    }

    final _BlocProviderInherited<T>? provider =
        inheritedElement.widget as _BlocProviderInherited<T>?;

    return provider?.bloc;
  }
}

class _BlocProviderState<T extends BaseBloc> extends State<BlocProvider<T>> {
  late T bloc;

  @override
  void initState() {
    super.initState();
    bloc = widget.blocBuilder();
  }

  @override
  void dispose() {
    if (widget.blocDisposer != null) {
      widget.blocDisposer?.call(bloc);
    } else {
      bloc.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BlocProviderInherited<T>(
      bloc: bloc,
      child: widget.child,
    );
  }
}

class _BlocProviderInherited<T extends BaseBloc> extends InheritedWidget {
  const _BlocProviderInherited({
    Key? key,
    required Widget child,
    required this.bloc,
  }) : super(key: key, child: child);

  final T bloc;

  @override
  bool updateShouldNotify(_BlocProviderInherited<T> oldWidget) => false;
}

extension ForwardFailure<T> on Stream<Either<Failure, T>> {
  Stream<T> onFailureForwardTo(StreamSink<Failure> failureSink) {
    return doOnData((event) {
      event.leftMap(failureSink.add);
    })
        .where((event) => event.isRight())
        // Workaround, basically returning null will never happen as we only take isRight() events
        .map((event) => event.fold((f) => null, (r) => r)!);
  }
}
