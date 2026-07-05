import 'dart:async';

import 'package:base_core/base_core.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'core/demo_users.dart';
import 'core/di/injector.dart';
import 'features/session/presentation/controllers/session_controller.dart';
import 'features/team/presentation/pages/members_page.dart';

void main() {
  BaseCoreLogger.instance.register(
    Logger(level: Level.debug, printer: SimplePrinter()),
  );
  configureDependencies();
  // Establish the demo session; in a real app this follows your auth flow.
  unawaited(getIt<SessionController>().signIn(demoUserIds.first));
  runApp(const TeamDirectoryApp());
}

class TeamDirectoryApp extends StatelessWidget {
  const TeamDirectoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Directory',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MembersPage(),
    );
  }
}
