import '../delivery/commands/send_electronic_invoice/send_electronic_invoice_result.dart';
import '../delivery/commands/start_auto_delivery/start_auto_delivery_result.dart';
import '../delivery/shared/auto_delivery_start_request.dart';
import '../delivery/shared/delivery_attempt_context_dto.dart';
import '../delivery/shared/delivery_result_record.dart';
import '../delivery/shared/manual_delivery_start_request.dart';
import '../delivery/shared/prepare_delivery_provider_call_result.dart';
import '../delivery/commands/record_delivery_result/record_delivery_result_result.dart';

abstract interface class IDeliveryCommandGateway {
  Future<AutoDeliveryResultDto> startAuto(AutoDeliveryStartRequest request);

  Future<SendInvoiceResultDto> startManual(ManualDeliveryStartRequest request);

  Future<DeliveryAttemptContextDto?> loadAttemptContext({
    required String tenantId,
    required String deliveryId,
    required int retryCount,
  });

  Future<PrepareDeliveryProviderCallResult> prepareProviderCall({
    required String tenantId,
    required String deliveryId,
    required int retryCount,
    required String requestReference,
  });

  Future<RecordDeliveryResultDto> recordResult(DeliveryResultRecord record);

  Future<void> recordCommandDeadLetter({
    required String tenantId,
    required String deliveryId,
    required int retryCount,
    required String safeFailureCode,
  });
}
