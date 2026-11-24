import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Quay về từ màn quyết toán (vd. sau PRICE_CHANGED) phải làm mới giá món đổi;
/// nếu không, lần "Tiếp tục" sau bỏ qua lưu (dòng không đổi) và lặp lại lỗi.
void main() {
  test('return/exchange session refreshes exchange prices after settlement', () {
    final source = File(
      'lib/features/sales/presentation/pages/sales_return_exchange_create_page.dart',
    ).readAsStringSync();
    final start = source.indexOf('Future<void> _handleProceed() async {');
    expect(start, greaterThanOrEqualTo(0));
    final body = source.substring(start, source.indexOf('\n  }\n', start));
    expect(body, contains('await SalesReturnSettleRoute('));
    expect(body, contains('await _cubit.refreshExchangePrices();'));
    expect(
      body.indexOf('await SalesReturnSettleRoute('),
      lessThan(body.indexOf('await _cubit.refreshExchangePrices();')),
    );
  });
}
