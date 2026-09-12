/// Domain status / kind enums for the Sales bounded context.
///
/// Kept separate from [domain.dart] while application still owns duplicate
/// names in `sales_contract_enums.dart` (contract freeze). Prefer this library
/// from domain tests and future BE handlers; migrate application DTOs later.
library;

export 'src/enums/return_exchange_line_kind.dart';
export 'src/enums/return_exchange_status.dart';
export 'src/enums/sales_draft_status.dart';
export 'src/enums/sales_order_cancellation_status.dart';
export 'src/enums/sales_order_lifecycle_status.dart';
export 'src/enums/sales_order_lock_status.dart';
export 'src/enums/sales_order_return_status.dart';
export 'src/enums/sales_payment_method.dart';
export 'src/enums/sales_payment_status.dart';
export 'src/enums/sales_payment_transaction_kind.dart';
export 'src/enums/sales_receipt_activity_type.dart';
export 'src/enums/sales_receipt_status.dart';
export 'src/enums/sales_settlement_status.dart';
