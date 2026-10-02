import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../electronic_invoice/shared/provider_call_correlation_id.dart';
import '../../../ports/i_delivery_command_gateway.dart';
import '../../../ports/i_einvoice_command_dispatcher.dart';
import '../../../ports/i_invoice_delivery_provider_port.dart';
import '../../shared/delivery_provider_outcome.dart';
import '../../shared/delivery_result_evidence.dart';
import '../../shared/delivery_result_kind.dart';
import '../../shared/prepare_delivery_provider_call_result.dart';
import '../record_delivery_result/record_delivery_result_command.dart';
import 'send_invoice_email_command.dart';

@CommandHandlerFor(SendInvoiceEmailCommand)
final class SendInvoiceEmailCommandHandler
    implements ICommandHandler<SendInvoiceEmailCommand, void> {
  SendInvoiceEmailCommandHandler({
    required IDeliveryCommandGateway commandGateway,
    required IInvoiceDeliveryProviderPort providerPort,
    required IEinvoiceCommandDispatcher commandDispatcher,
  }) : _commandGateway = commandGateway,
       _providerPort = providerPort,
       _commandDispatcher = commandDispatcher;

  final IDeliveryCommandGateway _commandGateway;
  final IInvoiceDeliveryProviderPort _providerPort;
  final IEinvoiceCommandDispatcher _commandDispatcher;

  @override
  Future<void> handle(SendInvoiceEmailCommand command) async {
    final context = await _commandGateway.loadAttemptContext(
      tenantId: command.tenantId,
      deliveryId: command.deliveryId,
      retryCount: command.retryCount,
    );
    if (context == null) {
      return;
    }

    final requestReference = ProviderCallCorrelationId.forWorkerAttempt(
      commandId: command.id,
      workerAttemptNumber: command.workerAttemptNumber,
    );

    final preparation = await _commandGateway.prepareProviderCall(
      tenantId: command.tenantId,
      deliveryId: command.deliveryId,
      retryCount: command.retryCount,
      requestReference: requestReference,
    );

    switch (preparation) {
      case PrepareDeliverySkip():
        return;
      case PrepareDeliveryRecordUnknown(:final deliveryVersion):
        await _record(
          command,
          deliveryVersion,
          const DeliveryResultEvidence(
            kind: DeliveryResultKind.undetermined,
            safeCode: 'DISPATCH_STATE_UNCERTAIN',
            failureSource: FailureSource.internal,
          ),
        );
        return;
      case PrepareDeliveryCallProvider(
        :final providerContext,
        :final deliveryVersion,
      ):
        // Đã qua chốt SUBMITTED: lỗi đường truyền không được thành "thử lại
        // chung" (có thể gửi thư hai lần) → UNDETERMINED + INTERNAL.
        DeliveryResultEvidence evidence;
        try {
          evidence = _evidenceFor(await _providerPort.sendEmail(providerContext));
        } catch (_) {
          evidence = const DeliveryResultEvidence(
            kind: DeliveryResultKind.undetermined,
            safeCode: 'PROVIDER_TRANSPORT_FAILURE',
            failureSource: FailureSource.internal,
          );
        }
        // Ghi kết quả lỗi thì ném lại: hàng đợi chạy lại lệnh, prepare thấy
        // SUBMITTED → RECORD_UNKNOWN, không gọi MISA lần hai.
        await _record(command, deliveryVersion, evidence);
    }
  }

  DeliveryResultEvidence _evidenceFor(DeliveryProviderOutcome outcome) =>
      switch (outcome) {
        DeliveryProviderSucceeded(:final providerReference) =>
          DeliveryResultEvidence(
            kind: DeliveryResultKind.success,
            providerReference: providerReference,
          ),
        DeliveryProviderDefiniteFailure(:final safeErrorCode) =>
          DeliveryResultEvidence(
            kind: DeliveryResultKind.definiteFailure,
            safeCode: safeErrorCode,
            failureSource: FailureSource.provider,
          ),
        DeliveryProviderRetryableFailure(:final safeErrorCode) =>
          DeliveryResultEvidence(
            kind: DeliveryResultKind.retryableFailure,
            safeCode: safeErrorCode,
            failureSource: FailureSource.provider,
          ),
        DeliveryProviderUndetermined(:final safeErrorCode) =>
          DeliveryResultEvidence(
            kind: DeliveryResultKind.undetermined,
            safeCode: safeErrorCode,
            failureSource: FailureSource.provider,
          ),
      };

  Future<void> _record(
    SendInvoiceEmailCommand command,
    int deliveryVersion,
    DeliveryResultEvidence evidence,
  ) => _commandDispatcher.execute(
    RecordDeliveryResultCommand(
      tenantId: command.tenantId,
      deliveryId: command.deliveryId,
      retryCount: command.retryCount,
      expectedDeliveryVersion: deliveryVersion,
      evidence: evidence,
    ),
  );
}
