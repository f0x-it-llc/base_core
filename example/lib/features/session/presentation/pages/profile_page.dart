import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/failure_listener.dart';
import '../../domain/entities/user_profile.dart';
import '../controllers/session_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // App-scoped singleton: looked up, NOT owned. The page must not dispose
  // it — contrast with MembersPage, which owns its factory-scoped controller.
  final SessionController _session = getIt<SessionController>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final renamed = await _session.rename(_nameController.text);
    if (renamed && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated.')));
    }
  }

  Future<void> _switchUser() async {
    _nameController.clear();
    await _session.switchDemoUser();
  }

  @override
  Widget build(BuildContext context) {
    return FailureListener(
      failures: _session.failures,
      child: Scaffold(
        appBar: AppBar(title: const Text('Your profile')),
        body: SignalBuilder(
          builder: (_) => AsyncView<UserProfile>(
            state: _session.profile.value,
            builder: (profile) {
              if (_nameController.text.isEmpty) {
                _nameController.text = profile.name;
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 36,
                      child: Text(
                        _session.initial.value,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const Icon(Icons.workspace_premium_outlined),
                    title: Text(profile.title),
                    subtitle: const Text('Title'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: Text(profile.email),
                    subtitle: const Text('Email'),
                  ),
                  const Divider(height: 32),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SignalBuilder(
                    builder: (_) => FilledButton(
                      onPressed: _session.saving.value ? null : _save,
                      child: _session.saving.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _switchUser,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Switch demo user'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
