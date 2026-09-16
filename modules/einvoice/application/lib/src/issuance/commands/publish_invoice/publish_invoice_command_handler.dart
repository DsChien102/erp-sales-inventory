import 'dart:async';

import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_issuance_result_gateway.dart';
import '../../../ports/i_me_invoice_provider_port.dart';
import '../../../ports/i_publish_series_lease_gateway.dart';
import '../../../ports/me_invoice_publish_outcome.dart';
import '../../shared/canonical_invoice_integrity_exception.dart';
import '../../shared/issuance_result_evidence_dto.dart';
import '../../shared/publish_preparation_action.dart';
import '../../shared/publish_series_lease_busy_exception.dart';
import 'publish_invoice_command.dart';

@CommandHandlerFor(PublishInvoiceCommand)
final class PublishInvoiceCommandHandler implements ICommandHandler<PublishInvoiceCommand, void> {
  PublishInvoiceCommandHandler({
    required IMeInvoiceProviderPort providerPort,
    required IIssuanceResultGateway resultGateway,
    required IPublishSeriesLeaseGateway leaseGateway,
    Duration leaseRenewInterval = const Duration(seconds: 30),
  }) : _providerPort = providerPort,
       _resultGateway = resultGateway,
       _leaseGateway = leaseGateway,
       _leaseRenewInterval = leaseRenewInterval;

  final IMeInvoiceProviderPort _providerPort;
  final IIssuanceResultGateway _resultGateway;
  final IPublishSeriesLeaseGateway _leaseGateway;
  final Duration _leaseRenewInterval;

  @override
  Future<void> handle(PublishInvoiceCommand command) async {
    try {
      _providerPort.validateCanonical(canonicalInvoice: command.canonicalInvoice);
    } catch (error) {
      if (error is CanonicalInvoiceIntegrityException) {
        rethrow;
      }
      throw CanonicalInvoiceIntegrityException(
        attemptId: command.attemptId,
        reasonCode: 'COMMAND_INTEGRITY',
        message: error.toString(),
      );
    }

    final leaseOutcome = await _leaseGateway.tryAcquire(
      tenantId: command.tenantId,
      attemptId: command.attemptId,
      ownerToken: command.id,
    );

    switch (leaseOutcome) {
      case PublishSeriesLeaseBusy(:final retryAfter):
        throw PublishSeriesLeaseBusyException(retryAfter: retryAfter);
      case PublishSeriesLeaseAcquired(
        :final providerConnectionId,
        :final invoiceSeries,
        :final leaseVersion,
      ):
        final heartbeat = _PublishSeriesLeaseHeartbeat(
          gateway: _leaseGateway,
          tenantId: command.tenantId,
          providerConnectionId: providerConnectionId,
          invoiceSeries: invoiceSeries,
          ownerToken: command.id,
          leaseVersion: leaseVersion,
          interval: _leaseRenewInterval,
        )..start();
        try {
          await _dispatchWithLease(command, heartbeat);
        } finally {
          await heartbeat.stop();
          await _leaseGateway.release(
            tenantId: command.tenantId,
            providerConnectionId: providerConnectionId,
            invoiceSeries: invoiceSeries,
            ownerToken: command.id,
            leaseVersion: leaseVersion,
          );
        }
    }
  }

  Future<void> _dispatchWithLease(
    PublishInvoiceCommand command,
    _PublishSeriesLeaseHeartbeat heartbeat,
  ) async {
    final preparation = await _resultGateway.preparePublish(
      tenantId: command.tenantId,
      attemptId: command.attemptId,
      idempotencyKey: command.idempotencyKey,
      payloadHash: command.payloadHash,
      canonicalInvoice: command.canonicalInvoice,
    );

    switch (preparation.action) {
      case PublishPreparationAction.skip:
        return;
      case PublishPreparationAction.reconcileOnly:
        await _resultGateway.recordUndetermined(
          tenantId: command.tenantId,
          attemptId: command.attemptId,
          evidence: IssuanceResultEvidenceDto.undetermined(
            idempotencyKey: command.idempotencyKey,
            payloadHash: command.payloadHash,
            reasonCode: 'DISPATCH_STATE_UNCERTAIN',
          ),
        );
        return;
      case PublishPreparationAction.callProvider:
        break;
    }

    _throwIfLeaseLost(heartbeat);

    await _resultGateway.markProviderCallStarted(
      tenantId: command.tenantId,
      attemptId: command.attemptId,
    );

    _throwIfLeaseLost(heartbeat);

    final outcome = await _providerPort.publish(
      tenantId: command.tenantId,
      canonicalInvoice: command.canonicalInvoice,
      idempotencyKey: command.idempotencyKey,
    );

    switch (outcome) {
      case MeInvoicePublishSuccess():
        await _resultGateway.recordSuccess(
          tenantId: command.tenantId,
          attemptId: command.attemptId,
          evidence: IssuanceResultEvidenceDto.success(
            idempotencyKey: command.idempotencyKey,
            payloadHash: command.payloadHash,
            providerReference: outcome.providerReference,
            invoiceNumber: outcome.invoiceNumber,
            invoiceSeries: outcome.invoiceSeries,
            issuedAt: outcome.issuedAt,
          ),
        );
      case MeInvoicePublishDefiniteFailure():
        await _resultGateway.recordDefiniteFailure(
          tenantId: command.tenantId,
          attemptId: command.attemptId,
          evidence: IssuanceResultEvidenceDto.definiteFailure(
            idempotencyKey: command.idempotencyKey,
            payloadHash: command.payloadHash,
            providerCode: outcome.providerCode,
            providerMessage: outcome.providerMessage,
          ),
        );
      case MeInvoicePublishRetryableRejection(:final retryAfter):
        await _resultGateway.recordRetryableProviderRejection(
          tenantId: command.tenantId,
          attemptId: command.attemptId,
          sourceCommandId: command.id,
          evidence: IssuanceResultEvidenceDto.retryableProviderRejection(
            idempotencyKey: command.idempotencyKey,
            payloadHash: command.payloadHash,
            providerCode: outcome.providerCode,
            providerMessage: outcome.providerMessage,
          ),
          retryAfter: retryAfter,
        );
      case MeInvoicePublishUndetermined():
        await _resultGateway.recordUndetermined(
          tenantId: command.tenantId,
          attemptId: command.attemptId,
          evidence: IssuanceResultEvidenceDto.undetermined(
            idempotencyKey: command.idempotencyKey,
            payloadHash: command.payloadHash,
            reasonCode: outcome.reasonCode,
          ),
        );
    }
  }

  void _throwIfLeaseLost(_PublishSeriesLeaseHeartbeat heartbeat) {
    if (heartbeat.isLost) {
      throw const PublishSeriesLeaseBusyException(
        retryAfter: Duration(seconds: 1),
      );
    }
  }
}

final class _PublishSeriesLeaseHeartbeat {
  _PublishSeriesLeaseHeartbeat({
    required IPublishSeriesLeaseGateway gateway,
    required String tenantId,
    required String providerConnectionId,
    required String invoiceSeries,
    required String ownerToken,
    required int leaseVersion,
    required Duration interval,
  }) : _gateway = gateway,
       _tenantId = tenantId,
       _providerConnectionId = providerConnectionId,
       _invoiceSeries = invoiceSeries,
       _ownerToken = ownerToken,
       _leaseVersion = leaseVersion,
       _interval = interval;

  final IPublishSeriesLeaseGateway _gateway;
  final String _tenantId;
  final String _providerConnectionId;
  final String _invoiceSeries;
  final String _ownerToken;
  final int _leaseVersion;
  final Duration _interval;

  Timer? _timer;
  Future<void>? _inFlight;
  bool _stopped = false;
  bool _lost = false;

  bool get isLost => _lost;

  void start() => _scheduleNext();

  void _scheduleNext() {
    if (_stopped || _lost) {
      return;
    }
    _timer = Timer(_interval, () {
      final renewal = _renewOnce();
      _inFlight = renewal;
      unawaited(
        renewal.whenComplete(() {
          if (identical(_inFlight, renewal)) {
            _inFlight = null;
          }
          _scheduleNext();
        }),
      );
    });
  }

  Future<void> _renewOnce() async {
    try {
      final outcome = await _gateway.renew(
        tenantId: _tenantId,
        providerConnectionId: _providerConnectionId,
        invoiceSeries: _invoiceSeries,
        ownerToken: _ownerToken,
        leaseVersion: _leaseVersion,
      );
      if (outcome is PublishSeriesLeaseLost) {
        _lost = true;
      }
    } on Object {
      _lost = true;
    }
  }

  Future<void> stop() async {
    _stopped = true;
    _timer?.cancel();
    await _inFlight;
  }
}
