import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Mở CN-02 của một khách từ màn khác (SG-09, SG-14, PT-07).
///
/// iPhone `push` để quay lại được màn gốc; web `go` để cột trái chọn đúng khách.
void openCustomerReceivable(BuildContext context, String customerId) {
  final path = '/more/receivables/$customerId';
  if (kIsWeb) {
    context.go(path);
  } else {
    context.push(path);
  }
}
