/// Lỗi tầng ứng dụng đưa ra cho nơi gọi.
class ApplicationException implements Exception {
  const ApplicationException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Lệnh không qua được bước kiểm tra dữ liệu ở tầng ứng dụng.
final class ValidationException implements Exception {
  ValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
