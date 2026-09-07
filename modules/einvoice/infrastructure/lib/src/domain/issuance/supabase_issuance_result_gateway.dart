import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/einvoice_error_mapper.dart';
import 'issuance_rpc_mapper.dart';

final class SupabaseIssuanceResultGateway implements IIssuanceResultGateway {
  SupabaseIssuanceResultGateway({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<PublishPreparationDto> preparePublish({
    required String tenantId,
    required String attemptId,
    required String idempotencyKey,
    required String payloadHash,
    required Map<String, Object?> canonicalInvoice,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'prepare_issuance_publish',
        params: IssuanceRpcMapper.preparePublishParams(
          tenantId: tenantId,
          attemptId: attemptId,
          idempotencyKey: idempotencyKey,
          payloadHash: payloadHash,
          canonicalInvoice: canonicalInvoice,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('prepare_issuance_publish returned no rows');
      }
      return IssuanceRpcMapper.publishPreparationFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<void> markProviderCallStarted({
    required String tenantId,
    required String attemptId,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'mark_issuance_provider_call_started',
        params: IssuanceRpcMapper.markProviderCallStartedParams(
          tenantId: tenantId,
          attemptId: attemptId,
        ),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<RecordIssuanceResultDto> recordSuccess({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async {
    final successEvidence = _requireSuccessEvidence(evidence);
    try {
      final rows = await _rpcClient.callList(
        'record_issuance_success',
        params: IssuanceRpcMapper.recordSuccessParams(
          tenantId: tenantId,
          attemptId: attemptId,
          evidence: successEvidence,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('record_issuance_success returned no rows');
      }
      return IssuanceRpcMapper.recordIssuanceResultFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<RecordIssuanceResultDto> recordDefiniteFailure({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async {
    final failureEvidence = _requireDefiniteFailureEvidence(evidence);
    try {
      final rows = await _rpcClient.callList(
        'record_issuance_failure',
        params: IssuanceRpcMapper.recordDefiniteFailureParams(
          tenantId: tenantId,
          attemptId: attemptId,
          evidence: failureEvidence,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('record_issuance_failure returned no rows');
      }
      return IssuanceRpcMapper.recordIssuanceResultFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<RecordIssuanceResultDto> recordUndetermined({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async {
    final undeterminedEvidence = _requireUndeterminedEvidence(evidence);
    try {
      final rows = await _rpcClient.callList(
        'record_issuance_undetermined',
        params: IssuanceRpcMapper.recordUndeterminedParams(
          tenantId: tenantId,
          attemptId: attemptId,
          evidence: undeterminedEvidence,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('record_issuance_undetermined returned no rows');
      }
      return IssuanceRpcMapper.recordIssuanceResultFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<RecordIssuanceResultDto> recordCommandIntegrityFailure({
    required String tenantId,
    required String attemptId,
    required String reasonCode,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'record_issuance_command_integrity_failure',
        params: IssuanceRpcMapper.recordCommandIntegrityFailureParams(
          tenantId: tenantId,
          attemptId: attemptId,
          reasonCode: reasonCode,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException(
          'record_issuance_command_integrity_failure returned no rows',
        );
      }
      return IssuanceRpcMapper.recordIssuanceResultFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<RecordIssuanceResultDto> recordPublishCommandDeadLetter({
    required String tenantId,
    required String attemptId,
    required String reasonCode,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'record_publish_command_dead_letter',
        params: IssuanceRpcMapper.recordPublishCommandDeadLetterParams(
          tenantId: tenantId,
          attemptId: attemptId,
          reasonCode: reasonCode,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException(
          'record_publish_command_dead_letter returned no rows',
        );
      }
      return IssuanceRpcMapper.recordIssuanceResultFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  IssuanceSuccessEvidenceDto _requireSuccessEvidence(
    IssuanceResultEvidenceDto evidence,
  ) {
    if (evidence is! IssuanceSuccessEvidenceDto) {
      throw RpcException(
        'recordSuccess requires IssuanceSuccessEvidenceDto, got ${evidence.runtimeType}',
      );
    }
    return evidence;
  }

  IssuanceDefiniteFailureEvidenceDto _requireDefiniteFailureEvidence(
    IssuanceResultEvidenceDto evidence,
  ) {
    if (evidence is! IssuanceDefiniteFailureEvidenceDto) {
      throw RpcException(
        'recordDefiniteFailure requires IssuanceDefiniteFailureEvidenceDto, got ${evidence.runtimeType}',
      );
    }
    return evidence;
  }

  IssuanceUndeterminedEvidenceDto _requireUndeterminedEvidence(
    IssuanceResultEvidenceDto evidence,
  ) {
    if (evidence is! IssuanceUndeterminedEvidenceDto) {
      throw RpcException(
        'recordUndetermined requires IssuanceUndeterminedEvidenceDto, got ${evidence.runtimeType}',
      );
    }
    return evidence;
  }
}
