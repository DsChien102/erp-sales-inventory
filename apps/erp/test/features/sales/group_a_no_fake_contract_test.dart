import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Group A S03-S05 production flow contains no fake or hardcoded owner data', () {
    final repoRoot = _findRepoRoot();
    const files = <String>[
      'apps/erp/lib/features/sales/presentation/lookups/sales_catalog_product_lookup.dart',
      'apps/erp/lib/features/sales/presentation/lookups/sales_partner_customer_lookup.dart',
      'apps/erp/lib/features/sales/presentation/lookups/sales_pricing_lookup.dart',
      'apps/erp/lib/features/sales/presentation/pages/sales_order_compose_page.dart',
      'apps/erp/lib/features/sales/presentation/bloc/sales_order_draft/sales_compose_cubit.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_compose_price_adjust_sheet.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_compose_product_search_bar.dart',
    ];
    const forbidden = <String>[
      'SalesFakeData.seedProducts',
      "storeId: 'fake-store'",
      "storeId: 'store_default'",
      'Fake store',
      'fallback SalesFakeData',
      'FE shell',
      'demo catalog',
      'Sẽ áp dụng sau khi hoàn tất đơn',
    ];

    for (final path in files) {
      final source = File('${repoRoot.path}/$path').readAsStringSync();
      for (final marker in forbidden) {
        expect(source, isNot(contains(marker)), reason: '$path contains $marker');
      }
    }
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
