import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/failure_listener.dart';
import '../../../session/presentation/widgets/session_avatar.dart';
import '../../domain/entities/member.dart';
import '../controllers/members_controller.dart';
import 'member_detail_page.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  // The page owns its controller: created here, disposed here.
  late final MembersController _controller = getIt<MembersController>();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FailureListener(
      failures: _controller.failures,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Team'),
          actions: [
            // Reads only onlineCount — rebuilds only when that number changes.
            SignalBuilder(
              builder: (_) => Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('${_controller.onlineCount.value} online'),
                ),
              ),
            ),
            // App-scoped session state, readable from any page.
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SessionAvatar(),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name or role',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (text) => _controller.query.value = text,
              ),
            ),
            Expanded(
              child: SignalBuilder(
                builder: (_) {
                  // Both signals are read here, inside the SignalBuilder's
                  // build, so it re-renders when either changes. Reading them
                  // in a nested widget's build would escape dependency
                  // tracking.
                  final state = _controller.members.value;
                  final members = _controller.filtered.value;
                  return AsyncView<List<Member>>(
                    state: state,
                    onRetry: _controller.load,
                    builder: (_) {
                      if (members.isEmpty) {
                        return const Center(child: Text('No members match.'));
                      }
                      return RefreshIndicator(
                        onRefresh: _controller.load,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: members.length,
                          itemBuilder: (context, index) =>
                              _MemberTile(member: members[index]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(child: Text(member.name[0])),
          if (member.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(member.name),
      subtitle: Text(member.role),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MemberDetailPage(memberId: member.id),
        ),
      ),
    );
  }
}
