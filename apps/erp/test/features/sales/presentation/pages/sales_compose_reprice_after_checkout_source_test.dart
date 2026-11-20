import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compose reprices after returning from checkout', () {
    final source = File('lib/features/sales/presentation/pages/sales_order_compose_page.dart').readAsStringSync();
    final start = source.indexOf('case SalesCheckoutPrepareReady(:final args):');
    final branch = source.substring(start, source.indexOf('case SalesCheckoutPrepareBlocked', start));
    expect(branch, contains('await SalesCheckoutRoute(\$extra: args).push(context);'));
    expect(branch, contains('await _cubit.refreshPricingPreview();'));
  });
}
