import 'package:vet45_sales_application/application.dart';

import '../models/sales_order_draft/sales_compose_line_vm.dart';

/// Reconciles compose working lines with authoritative draft lines returned after
/// a successful persist. Server-owned fields (line id, persisted amounts) win;
/// catalog-only fields on the working state are preserved.
List<SalesComposeLineVm> reconcileComposeLinesAfterPersist({
  required List<SalesComposeLineVm> current,
  required List<SalesOrderDraftLineDto> persisted,
}) {
  if (current.length != persisted.length) {
    throw FormatException(
      'Persisted draft line count (${persisted.length}) '
      'does not match working state (${current.length}).',
    );
  }

  return [
    for (var i = 0; i < current.length; i++)
      SalesComposeLineVm.fromPersistedDraftMerge(
        local: current[i],
        persisted: persisted[i],
      ),
  ];
}
