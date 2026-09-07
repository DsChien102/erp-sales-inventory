import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/einvoice_error_mapper.dart';
import 'provider_interaction_rpc_mapper.dart';

final class SupabaseProviderInteractionGateway
    implements IProviderInteractionGateway {
  SupabaseProviderInteractionGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<ProviderInteractionRecord> start({
    required String tenantId,
    required String providerConnectionId,
    required ProviderInteractionDirection direction,
    required String operationType,
    required String targetType,
    required String targetId,
    required String correlationId,
    required String requestReference,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'start_provider_interaction',
        params: ProviderInteractionRpcMapper.startParams(
          tenantId: tenantId,
          providerConnectionId: providerConnectionId,
          direction: direction,
          operationType: operationType,
          targetType: targetType,
          targetId: targetId,
          correlationId: correlationId,
          requestReference: requestReference,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('start_provider_interaction returned no rows');
      }
      return ProviderInteractionRpcMapper.interactionFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<ProviderInteractionRecord> finalize({
    required String tenantId,
    required String interactionReference,
    required int expectedVersion,
    required ProviderInteractionOutcome outcome,
    String? responseReference,
    String? providerReference,
    String? safeErrorCode,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'record_provider_interaction_result',
        params: ProviderInteractionRpcMapper.finalizeParams(
          tenantId: tenantId,
          interactionReference: interactionReference,
          expectedVersion: expectedVersion,
          outcome: outcome,
          responseReference: responseReference,
          providerReference: providerReference,
          safeErrorCode: safeErrorCode,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException(
          'record_provider_interaction_result returned no rows',
        );
      }
      return ProviderInteractionRpcMapper.interactionFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
