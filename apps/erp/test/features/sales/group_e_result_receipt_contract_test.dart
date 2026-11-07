import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Group E result route args carry checkout identity only', () {
    final root = _findRepoRoot();
    final argsSource = File(
      '${root.path}/apps/erp/lib/features/sales/presentation/models/sales_order/sales_checkout_result_args.dart',
    ).readAsStringSync();

    expect(argsSource, contains('CheckoutResultDto'));
    expect(argsSource, isNot(contains('totalAmountMinor')));
    expect(argsSource, isNot(contains('paidAmountMinor')));
    expect(argsSource, isNot(contains('customerName')));
    expect(argsSource, isNot(contains('paymentMethodText')));
  });

  test('Group E ERP result page loads through repositories', () {
    final root = _findRepoRoot();
    final page = File(
      '${root.path}/apps/erp/lib/features/sales/presentation/pages/sales_transaction_result_page.dart',
    ).readAsStringSync();
    final checkout = File(
      '${root.path}/apps/erp/lib/features/sales/presentation/pages/sales_checkout_page.dart',
    ).readAsStringSync();

    expect(page, contains('GetIt.instance<SalesReceiptRepository>'));
    expect(page, contains('SalesTransactionResultCubit'));
    expect(page, contains('..load()'));
    expect(page, isNot(contains('loadError')));
    expect(page, isNot(contains('receiptError')));
    expect(page, isNot(contains('orderNumber:')));
    expect(checkout, contains('SalesCheckoutResultArgs(result: result, storeId:'));
    expect('$page\n$checkout', isNot(contains('Supabase')));
    expect('$page\n$checkout', isNot(contains('.rpc(')));
    expect('$page\n$checkout', isNot(contains('.from(')));
  });
}

Directory _findRepoRoot() {
  var directory = Directory.current.absolute;
  while (directory.parent.path != directory.path) {
    if (File('${directory.path}/AGENTS.md').existsSync() &&
        Directory('${directory.path}/apps/erp').existsSync()) {
      return directory;
    }
    directory = directory.parent;
  }
  throw StateError('Unable to locate the Vet45 repository root');
}
