import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guard: Group I production paths must not retain demo/fake markers.
///
/// Scope is an **explicit** Group I file list only (S28–S34 session/settlement/
/// detail cubits + mappers/VMs + widgets + ERP thin pages + slip PDF path).
void main() {
  test('Group I S28-S34 production path contains no demo markers', () {
    final repoRoot = _findRepoRoot();
    const files = <String>[
      // Cubits / state
      'apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_session_cubit.dart',
      'apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_session_state.dart',
      'apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_settlement_cubit.dart',
      'apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_settlement_state.dart',
      'apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_detail_cubit.dart',
      'apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_detail_state.dart',
      // Support / mappers
      'apps/erp/lib/features/sales/presentation/support/sales_return_exchange_attempt_factory.dart',
      'apps/erp/lib/features/sales/presentation/support/sales_return_exchange_mapper.dart',
      'apps/erp/lib/features/sales/presentation/support/sales_return_exchange_session_draft.dart',
      'apps/erp/lib/features/sales/presentation/support/sales_slip_pdf_generator.dart',
      // VMs / outcome
      'apps/erp/lib/features/sales/presentation/models/return_exchange_order/sales_return_exchange_detail_vm.dart',
      'apps/erp/lib/features/sales/presentation/models/return_exchange_order/sales_return_exchange_result.dart',
      'apps/erp/lib/features/sales/presentation/models/return_exchange_order/sales_return_exchange_session_vm.dart',
      'apps/erp/lib/features/sales/presentation/models/return_exchange_order/sales_return_exchange_settlement_vm.dart',
      // Widgets
      'apps/erp/lib/features/sales/presentation/widgets/sales_return_exchange_session_body.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_return_exchange_session_line_rows.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_return_exchange_settlement_body.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_return_exchange_result_body.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_return_exchange_detail_body.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_return_confirm_settlement_sheet.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_exchange_product_picker_sheet.dart',
      'apps/erp/lib/features/sales/presentation/pages/sales_slip_preview_page.dart',
      // ERP thin pages
      'apps/erp/lib/features/sales/presentation/pages/sales_return_exchange_create_page.dart',
      'apps/erp/lib/features/sales/presentation/pages/sales_return_exchange_settlement_page.dart',
      'apps/erp/lib/features/sales/presentation/pages/sales_return_exchange_result_page.dart',
      'apps/erp/lib/features/sales/presentation/pages/sales_return_exchange_detail_page.dart',
      'apps/erp/lib/features/sales/presentation/pages/sales_return_exchange_slip_preview_page.dart',
      // Router
      'apps/erp/lib/core/router/app_router.dart',
    ];

    const forbidden = <String>[
      '_demoCatalog',
      '_defaultVm',
      'orderId.toUpperCase()',
      'ret_\${',
      'idemp_ret_',
      'hash_ret_',
      'corr_ret_',
      'expectedVersion: 1',
      'Nguyễn Văn An',
      '0903 456 789',
      'DT-00018',
      'DH-000129',
      '22/07/2026',
      'PDT-20260722-0018',
      'catch (_) {}',
      'SalesReturnExchangeCubit',
      'SalesReturnExchangeVm',
      'extra: _cubit',
      'extra: vm',
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

    final router = File(
      '${repoRoot.path}/apps/erp/lib/core/router/app_router.dart',
    ).readAsStringSync();
    final typedRoutes = File(
      '${repoRoot.path}/apps/erp/lib/features/sales/presentation/navigation/sales_typed_routes.dart',
    ).readAsStringSync();
    expect(router, contains(r'...$appRoutes'), reason: 'missing sales \$appRoutes mount');
    for (final symbol in const [
      'SalesReturnSettleRoute',
      'SalesReturnResultRoute',
      'SalesReturnDetailRoute',
      'SalesReturnPreviewRoute',
    ]) {
      expect(typedRoutes, contains(symbol), reason: 'missing $symbol');
    }
    for (final segment in const [
      '/sales/orders/:orderId/returns/:returnExchangeId/settle',
      '/sales/orders/:orderId/returns/:returnExchangeId/result',
      '/sales/orders/:orderId/returns/:returnExchangeId/detail',
      '/sales/orders/:orderId/returns/:returnExchangeId/preview',
    ]) {
      expect(
        typedRoutes,
        contains(segment),
        reason: 'missing route template $segment in sales_typed_routes',
      );
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
