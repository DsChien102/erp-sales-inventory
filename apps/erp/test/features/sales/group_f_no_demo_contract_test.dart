import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guard: Group F production paths must not retain demo/fake markers.
///
/// Scope is an **explicit** Group F file list only (S15–S21 list/detail/mappers/
/// VMs + payment/history/return widgets + ERP list/detail pages +
/// slip preview).
void main() {
  test('Group F S15-S21 production path contains no demo or direct Supabase access', () {
    final repoRoot = _findRepoRoot();
    const files = <String>[
      // Cubits / state
      'apps/erp/lib/features/sales/logic/sales_order_list_cubit.dart',
      'apps/erp/lib/features/sales/logic/sales_order_list_state.dart',
      'apps/erp/lib/features/sales/logic/sales_order_detail_cubit.dart',
      'apps/erp/lib/features/sales/logic/sales_order_detail_state.dart',
      'apps/erp/lib/features/sales/logic/sales_order_detail_post_sale_actions.dart',
      'apps/erp/lib/features/sales/logic/sales_order_detail_sections_loader.dart',
      // Mappers / support
      'apps/erp/lib/features/sales/presentation/support/sales_order_list_mapper.dart',
      'apps/erp/lib/features/sales/presentation/support/sales_order_detail_mapper.dart',
      'apps/erp/lib/features/sales/logic/sales_receipt_operation_handler.dart',
      // VMs S15–S21
      'apps/erp/lib/features/sales/presentation/models/sales_order/sales_order_list_item_vm.dart',
      'apps/erp/lib/features/sales/presentation/models/sales_order/sales_order_list_filters.dart',
      'apps/erp/lib/features/sales/presentation/models/sales_order/sales_order_detail_vm.dart',
      'apps/erp/lib/features/sales/presentation/models/sales_order/sales_order_actions_vm.dart',
      'apps/erp/lib/features/sales/presentation/models/sales_order/sales_order_history_vm.dart',
      'apps/erp/lib/features/sales/presentation/models/sales_order_settlement/sales_order_payment_vm.dart',
      'apps/erp/lib/features/sales/presentation/models/sales_order/sales_post_sale_navigation_intent.dart',
      'apps/erp/lib/features/sales/presentation/models/sales_receipt/sales_receipt_operation_state.dart',
      // Widgets Task 3–11
      'apps/erp/lib/features/sales/presentation/widgets/sales_order_list_body.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_order_detail_body.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_order_detail_payment_summary_card.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_order_detail_returns_section.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_order_detail_error_state.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_order_history_page.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_order_payment_debt_page.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_order_return_list_page.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_detail_action_bar.dart',
      'apps/erp/lib/features/sales/presentation/widgets/sales_order_actions_sheet.dart',
      // Preview page (module presentation; ERP routes to it)
      'apps/erp/lib/features/sales/presentation/pages/sales_order_slip_preview_page.dart',
      // ERP list/detail pages
      'apps/erp/lib/features/sales/presentation/pages/sales_order_list_page.dart',
      'apps/erp/lib/features/sales/presentation/pages/sales_order_detail_page.dart',
      // Public barrel + example catalog wiring
      'apps/erp/lib/features/sales/presentation.dart',
      'apps/erp/example/lib/sales/preview/overview_tab.dart',
    ];
    const forbidden = <String>[
      'so-demo-',
      "contains('cancel')",
      "contains('return')",
      "contains('d04')",
      "contains('d06')",
      '#DT-00018',
      'DateTime(2026, 7, 29',
      '0903 456 789',
      'Cửa hàng Trung tâm',
      'catch (_) {}',
      'SalesFeShellModule',
      '.rpc(',
      '.from(',
      'package:supabase',
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
