class LaropayInvalidResponseException implements Exception {
  const LaropayInvalidResponseException(this.message);

  final String message;

  @override
  String toString() => 'LaropayInvalidResponseException';
}
