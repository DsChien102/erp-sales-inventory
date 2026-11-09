import 'package:uuid/uuid.dart';

/// Sinh khoá idempotency cho các lệnh ghi kho.
String newIdempotencyKey() => const Uuid().v4();
