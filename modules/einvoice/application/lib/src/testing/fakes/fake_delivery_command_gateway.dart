import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

/// In-memory [IDeliveryCommandGateway] for delivery handler tests.
final class FakeDeliveryCommandGateway implements IDeliveryCommandGateway {
  FakeDeliveryCommandGateway();

  factory FakeDeliveryCommandGateway.started({String deliveryId = 'del-1'}) {
    return FakeDeliveryCommandGateway()
      ..startAutoResult = AutoDeliveryResultDto(
        disposition: AutoDeliveryDisposition.started,
        deliveryId: deliveryId,
      );
  }

  factory FakeDeliveryCommandGateway.skipped(AutoDeliverySkipReason reason) {
    return FakeDeliveryCommandGateway()
      ..startAutoResult = AutoDeliveryResultDto(
        disposition: AutoDeliveryDisposition.skipped,
        skipReason: reason,
      );
  }

  factory FakeDeliveryCommandGateway.manualStarted({
    String deliveryId = 'del-1',
  }) {
    return FakeDeliveryCommandGateway()
      ..startManualResult = SendInvoiceResultDto(
        deliveryId: deliveryId,
        status: DeliveryStatus.processing,
      );
  }

  AutoDeliveryStartRequest? lastStartAuto;
  ManualDeliveryStartRequest? lastStartManual;
  DeliveryResultRecord? lastRecordResult;
  AutoDeliveryResultDto startAutoResult = const AutoDeliveryResultDto(
    disposition: AutoDeliveryDisposition.started,
    deliveryId: 'del-1',
  );
  SendInvoiceResultDto startManualResult = const SendInvoiceResultDto(
    deliveryId: 'del-1',
    status: DeliveryStatus.processing,
  );
  DeliveryAttemptContextDto? attemptContext;
  PrepareDeliveryProviderCallResult prepareResult = const PrepareDeliverySkip();
  RecordDeliveryResultDto recordResultDto = const RecordDeliveryResultDto(
    deliveryStatus: DeliveryStatus.processing,
    displayState: DeliveryDisplayState.sending,
    hasSecondaryAttention: false,
  );

  @override
  Future<AutoDeliveryResultDto> startAuto(
    AutoDeliveryStartRequest request,
  ) async {
    lastStartAuto = request;
    return startAutoResult;
  }

  @override
  Future<SendInvoiceResultDto> startManual(
    ManualDeliveryStartRequest request,
  ) async {
    lastStartManual = request;
    return startManualResult;
  }

  @override
  Future<DeliveryAttemptContextDto?> loadAttemptContext({
    required String tenantId,
    required String deliveryId,
    required int retryCount,
  }) async {
    return attemptContext;
  }

  @override
  Future<PrepareDeliveryProviderCallResult> prepareProviderCall({
    required String tenantId,
    required String deliveryId,
    required int retryCount,
    required String requestReference,
  }) async {
    return prepareResult;
  }

  @override
  Future<RecordDeliveryResultDto> recordResult(
    DeliveryResultRecord record,
  ) async {
    lastRecordResult = record;
    return recordResultDto;
  }

  @override
  Future<void> recordCommandDeadLetter({
    required String tenantId,
    required String deliveryId,
    required int retryCount,
    required String safeFailureCode,
  }) async {}
}
