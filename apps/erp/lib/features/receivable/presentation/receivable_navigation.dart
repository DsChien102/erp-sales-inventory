import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Mở CN-02 của một khách từ màn khác (SG-09, SG-14, PT-07).
///
/// iPhone `push` và đợi tới khi quay lại, để màn gọi tải lại số công nợ; web `go`
/// để cột trái chọn đúng khách (không có "quay lại", Future xong ngay).
Future<void> openCustomerReceivable(BuildContext context, String customerId) async {
  final path = '/more/receivables/$customerId';
  if (kIsWeb) {
    context.go(path);
  } else {
    await context.push<void>(path);
  }
}
