import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../enums/sales_order_return_status.dart';

/// Derives the independent SalesOrder return-status projection from quantities.
final class SalesOrderReturnStatusCalculator {
  const SalesOrderReturnStatusCalculator();

  SalesOrderReturnStatus calculate({
    required int totalSoldMicros,
    required int totalCompletedReturnedMicros,
  }) {
    if (totalSoldMicros < 0 || totalCompletedReturnedMicros < 0) {
      throw DomainException(
        'Sold and completed-returned quantities must not be negative.',
      );
    }
    if (totalCompletedReturnedMicros > totalSoldMicros) {
      throw DomainException(
        'Completed returned quantity cannot exceed total sold quantity.',
      );
    }
    if (totalCompletedReturnedMicros == 0) {
      return SalesOrderReturnStatus.none;
    }
    if (totalCompletedReturnedMicros >= totalSoldMicros) {
      return SalesOrderReturnStatus.fullyReturned;
    }
    return SalesOrderReturnStatus.partiallyReturned;
  }
}
