/// Transport-level error, as an http client would throw it.
///
/// Never leaves the data layer — repository implementations map it to a
/// domain Failure in one place.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'ApiException($statusCode): $body';
}
