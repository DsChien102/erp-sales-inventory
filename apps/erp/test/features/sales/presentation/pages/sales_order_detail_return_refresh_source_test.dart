import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sau khi quay về từ luồng đổi/trả, chi tiết đơn phải tải lại (version và
/// dòng hàng đã đổi) — giống nhánh hủy đơn.
void main() {
  test('return/exchange branch refreshes the detail after the route returns', () {
    final source = File(
      'lib/features/sales/presentation/pages/sales_order_detail_page.dart',
    ).readAsStringSync();
    final start = source.indexOf('case SalesPostSaleNavigationIntent.returnExchange:');
    expect(start, isNonNegative);
    final branch = source.substring(start, source.indexOf('}', start));
    final pushAt = branch.indexOf('await SalesReturnNewRoute(orderId: widget.orderId).push(context);');
    final refreshAt = branch.indexOf('await _cubit.refresh();');
    expect(pushAt, isNonNegative);
    expect(refreshAt, greaterThan(pushAt));
    expect(branch, contains('if (!mounted) return;'));
  });
}
