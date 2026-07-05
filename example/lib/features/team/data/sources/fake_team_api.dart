import 'dart:async';
import 'dart:math';

import '../../../../core/network/api_exception.dart';

/// In-memory stand-in for a remote API.
///
/// Simulates what makes real backends annoying:
/// - [latency] on every call,
/// - the first [failuresBeforeSuccess] list fetches return HTTP 500
///   (which the repository maps to a retryable NetworkFailure — watch the
///   controller's RetryPolicy absorb them),
/// - a presence channel that pushes a new set of online users every
///   [presenceInterval].
class FakeTeamApi {
  FakeTeamApi({
    this.latency = const Duration(milliseconds: 400),
    this.failuresBeforeSuccess = 2,
    this.presenceInterval = const Duration(seconds: 3),
    int randomSeed = 7,
  }) : _random = Random(randomSeed);

  final Duration latency;
  final int failuresBeforeSuccess;
  final Duration presenceInterval;
  final Random _random;

  int _listFetches = 0;

  final Map<String, Map<String, Object?>> _db = {
    'u1': {'id': 'u1', 'name': 'Ava Chen', 'role': 'Mobile Engineer', 'email': 'ava@team.dev'},
    'u2': {'id': 'u2', 'name': 'Bruno Costa', 'role': 'Backend Engineer', 'email': 'bruno@team.dev'},
    'u3': {'id': 'u3', 'name': 'Chidi Okafor', 'role': 'Product Designer', 'email': 'chidi@team.dev'},
    'u4': {'id': 'u4', 'name': 'Dana Weiss', 'role': 'Engineering Manager', 'email': 'dana@team.dev'},
    'u5': {'id': 'u5', 'name': 'Emre Yilmaz', 'role': 'QA Engineer', 'email': 'emre@team.dev'},
    'u6': {'id': 'u6', 'name': 'Freja Lund', 'role': 'Mobile Engineer', 'email': 'freja@team.dev'},
  };

  Future<List<Map<String, Object?>>> fetchMembers() async {
    await Future<void>.delayed(latency);
    if (_listFetches++ < failuresBeforeSuccess) {
      throw const ApiException(500, 'temporary upstream error');
    }
    return _db.values.map(Map<String, Object?>.from).toList();
  }

  Future<Map<String, Object?>> fetchMember(String id) async {
    await Future<void>.delayed(latency);
    final row = _db[id];
    if (row == null) throw ApiException(404, 'no member $id');
    return Map<String, Object?>.from(row);
  }

  Future<Map<String, Object?>> patchMemberName(String id, String name) async {
    await Future<void>.delayed(latency);
    final row = _db[id];
    if (row == null) throw ApiException(404, 'no member $id');
    row['name'] = name;
    return Map<String, Object?>.from(row);
  }

  /// Pushes a random subset of user ids as "online" on every tick.
  /// Implemented on Stream.periodic so cancelling the subscription
  /// cancels the underlying timer immediately.
  Stream<List<String>> presenceEvents() =>
      Stream<void>.periodic(presenceInterval).map(
        (_) => _db.keys.where((_) => _random.nextBool()).toList(),
      );
}
