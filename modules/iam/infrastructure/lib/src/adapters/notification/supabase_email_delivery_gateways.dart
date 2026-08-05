import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_error_mapper.dart';

/// Projection store for email delivery outcomes via Supabase RPCs.
final class SupabaseEmailDeliveryOutcomeGateway implements IEmailDeliveryOutcomeStore {
  SupabaseEmailDeliveryOutcomeGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<String> record({
    required String correlationId,
    required EmailTemplateId templateId,
    required EmailDeliveryStatus status,
    String? tenantId,
    String? toEmailMasked,
    String? providerMessageId,
    String? error,
    String provider = EmailDeliveryConstants.providerResend,
    String? id,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_correlation_id': correlationId,
        'p_template_id': templateId.wireValue,
        'p_status': status.wireValue,
        'p_provider': provider,
        'p_tenant_id': tenantId,
        'p_to_email_masked': toEmailMasked,
        'p_provider_message_id': providerMessageId,
        'p_error': error,
      };
      if (id != null) {
        params['p_id'] = id;
      }
      final recordedId = await _rpcClient.callScalar<Object?>(
        'record_email_delivery_outcome',
        params: params,
      );
      return recordedId.toString();
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<EmailDeliveryOutcomeDto?> getByCorrelationId(
    String correlationId,
  ) async {
    try {
      final rows = await _rpcClient.callList(
        'get_email_delivery_outcome_by_correlation',
        params: <String, dynamic>{'p_correlation_id': correlationId},
      );
      if (rows.isEmpty) {
        return null;
      }
      return _mapOutcome(rows.first);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<bool> isCurrentTenantInvitationDelivery({
    required String invitationId,
    required String correlationId,
  }) async {
    try {
      final result = await _rpcClient.callScalar<bool>(
        'is_current_tenant_invitation_delivery',
        params: <String, dynamic>{
          'p_invitation_id': invitationId,
          'p_correlation_id': correlationId,
        },
      );
      return result ?? false;
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  static EmailDeliveryOutcomeDto _mapOutcome(Map<String, dynamic> row) {
    return EmailDeliveryOutcomeDto(
      id: row['id'].toString(),
      tenantId: row['tenant_id']?.toString(),
      templateId: EmailTemplateId.fromWire(row['template_id'] as String),
      status: EmailDeliveryStatus.fromWire(row['status'] as String),
      correlationId: row['correlation_id'] as String,
      provider: row['provider'] as String,
      providerMessageId: row['provider_message_id'] as String?,
      error: row['error'] as String?,
      toEmailMasked: row['to_email_masked'] as String?,
    );
  }
}
