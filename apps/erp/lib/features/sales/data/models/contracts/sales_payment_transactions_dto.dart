import 'opaque_cursor_page_dto.dart';
import 'sales_payment_transaction_dto.dart';

final class SalesPaymentTransactionsDto {
  const SalesPaymentTransactionsDto({required this.page});

  final OpaqueCursorPageDto<SalesPaymentTransactionDto> page;
}
