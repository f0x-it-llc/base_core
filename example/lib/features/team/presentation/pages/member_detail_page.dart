import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/failure_listener.dart';
import '../../domain/entities/member.dart';
import '../controllers/member_detail_controller.dart';

class MemberDetailPage extends StatefulWidget {
  const MemberDetailPage({super.key, required this.memberId});

  final String memberId;

  @override
  State<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage> {
  late final MemberDetailController _controller =
      getIt<MemberDetailController>(param1: widget.memberId);
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final renamed = await _controller.rename(_nameController.text);
    if (renamed && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name updated.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FailureListener(
      failures: _controller.failures,
      child: Scaffold(
        appBar: AppBar(title: const Text('Member')),
        body: SignalBuilder(
          builder: (_) => AsyncView<Member>(
            state: _controller.member.value,
            onRetry: _controller.load,
            builder: (member) {
              if (_nameController.text.isEmpty) {
                _nameController.text = member.name;
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 36,
                      child: Text(
                        member.name[0],
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      member.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: member.isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: Text(member.role),
                    subtitle: const Text('Role'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: Text(member.email),
                    subtitle: const Text('Email'),
                  ),
                  const Divider(height: 32),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SignalBuilder(
                    builder: (_) => FilledButton(
                      onPressed: _controller.saving.value ? null : _save,
                      child: _controller.saving.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
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
