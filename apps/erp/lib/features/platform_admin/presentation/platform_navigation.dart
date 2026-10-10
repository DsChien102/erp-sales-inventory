import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Quay lại; mở thẳng từ đường dẫn (không có ngăn xếp) thì về `/`.
void leavePlatformPage(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/');
  }
}
