// lib/services/api_exception.dart
// Custom exception thrown by the API service whenever the server returns
// a non-200 HTTP status code, as required by the assignment rubric.

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() =>
      'ApiException: HTTP $statusCode — $message';
}
