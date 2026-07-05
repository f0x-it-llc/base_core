import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/di/injector.dart';
import '../controllers/session_controller.dart';
import '../pages/profile_page.dart';

/// The signed-in user's avatar, mountable in any AppBar in the app.
///
/// Reads the app-scoped [SessionController] straight from get_it — session
/// state does not travel through the widget tree. Rebuilds only when the
/// user's initial changes; renaming yourself on the profile page updates
/// this chip on every page that shows it.
class SessionAvatar extends StatelessWidget {
  const SessionAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final session = getIt<SessionController>();
    return IconButton(
      tooltip: 'Your profile',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
      ),
      icon: SignalBuilder(
        builder: (_) => CircleAvatar(
          radius: 14,
          child: Text(session.initial.value, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}
