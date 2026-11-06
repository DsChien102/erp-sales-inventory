import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Group B S06-S07 production flow contains no fake or local draft paths', () {
    final repoRoot = _findRepoRoot();
    const files = <String>[
      'apps/erp/lib/features/sales/presentation/pages/sales_order_compose_page.dart',
      'apps/erp/lib/features/sales/presentation/pages/sales_draft_list_page.dart',
      'apps/erp/lib/features/sales/logic/sales_draft_backend.dart',
      'apps/erp/lib/features/sales/presentation/bloc/sales_order_draft/sales_compose_cubit.dart',
      'apps/erp/lib/features/sales/logic/sales_draft_list_cubit.dart',
      'apps/erp/lib/features/sales/presentation/bloc/sales_order_draft/sales_draft_contracts.dart',
      'apps/erp/lib/features/sales/presentation/support/i_sales_active_store_context.dart',
      'apps/erp/lib/features/sales/presentation.dart',
    ];
    const forbidden = <String>[
      'SalesDraftSessionStore',
      'SalesComposeRestoreCatalog',
      'SalesFakeData',
      'draft-demo',
      'draft-session',
      'fake-draft',
      'DateTime(2026, 7, 30',
      'saveDraftLocally',
    ];

    for (final path in files) {
      final file = File('${repoRoot.path}/$path');
      expect(file.existsSync(), isTrue, reason: 'missing $path');
      final source = file.readAsStringSync();
      for (final marker in forbidden) {
        expect(
          source,
          isNot(contains(marker)),
          reason: '$path contains $marker',
        );
      }
    }

    expect(
      File(
        'apps/erp/lib/features/sales/presentation/support/sales_draft_session_store.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      File(
        'apps/erp/lib/features/sales/presentation/support/sales_compose_restore_catalog.dart',
      ).existsSync(),
      isFalse,
    );
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
