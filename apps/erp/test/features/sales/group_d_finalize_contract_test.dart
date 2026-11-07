import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Group D UI finalizes only through SalesCheckoutRepository', () {
    final root = _findRepoRoot();
    final cubit = File(
      '${root.path}/apps/erp/lib/features/sales/logic/sales_checkout_cubit.dart',
    ).readAsStringSync();
    final page = File(
      '${root.path}/apps/erp/lib/features/sales/presentation/pages/sales_checkout_page.dart',
    ).readAsStringSync();

    expect(cubit, contains('repository.finalize'));
    expect(cubit, contains('repository.getResult'));
    expect(page, contains('showSalesCheckoutFinalizeSheet'));
    expect('$cubit\n$page', isNot(contains('Supabase')));
    expect('$cubit\n$page', isNot(contains('.rpc(')));
    expect('$cubit\n$page', isNot(contains('.from(')));
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
