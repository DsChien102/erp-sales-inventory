import '../delivery/shared/delivery_reconciliation_check_record.dart';
import '../delivery/shared/delivery_reconciliation_context_dto.dart';
import '../delivery/shared/delivery_reconciliation_result_dto.dart';

abstract interface class IDeliveryReconciliationGateway {
  Future<DeliveryReconciliationContextDto?> loadContext({
    required String tenantId,
    required String reconciliationCaseId,
    required int checkSequence,
  });

  Future<DeliveryReconciliationResultDto> recordCheck(
    DeliveryReconciliationCheckRecord record,
  );
}
