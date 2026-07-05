import '../../../../core/network/api_exception.dart';

/// In-memory stand-in for the profile endpoint of a remote API.
class FakeProfileApi {
  FakeProfileApi({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  final Map<String, Map<String, Object?>> _db = {
    'u-riley': {
      'id': 'u-riley',
      'name': 'Riley Park',
      'email': 'riley@team.dev',
      'title': 'Staff Engineer',
    },
    'u-jordan': {
      'id': 'u-jordan',
      'name': 'Jordan Lee',
      'email': 'jordan@team.dev',
      'title': 'Platform Lead',
    },
  };

  Future<Map<String, Object?>> fetchProfile(String userId) async {
    await Future<void>.delayed(latency);
    final row = _db[userId];
    if (row == null) throw ApiException(404, 'no profile $userId');
    return Map<String, Object?>.from(row);
  }

  Future<Map<String, Object?>> patchName(String userId, String name) async {
    await Future<void>.delayed(latency);
    final row = _db[userId];
    if (row == null) throw ApiException(404, 'no profile $userId');
    row['name'] = name;
    return Map<String, Object?>.from(row);
  }
}
