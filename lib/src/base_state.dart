import 'package:base_core/base_core.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

abstract class BaseState<T extends StatefulWidget> extends State<T> {
  late Logger logger;
  BaseState() {
    logger = BaseCoreLogger.instance.logger;
    logger.i('init');
  }

  CompositeSubscription compositeSubscription = CompositeSubscription();

  @override
  void dispose() {
    logger.i('dispose');
    compositeSubscription.dispose();
    super.dispose();
  }
}
