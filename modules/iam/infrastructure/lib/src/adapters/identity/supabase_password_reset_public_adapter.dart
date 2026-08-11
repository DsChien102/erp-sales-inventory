import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_blocked_error_mapper.dart';

/// RPC adapter for logged-out forgot-password.
final class SupabasePasswordResetPublicAdapter
    implements IPasswordResetPublicPort {
  SupabasePasswordResetPublicAdapter({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<PasswordResetRequestResultDto> requestByEmail({
    required String email,
  }) =>
      _request('begin_password_reset_operation_by_email', {
        'p_email': email,
      });

  @override
  Future<PasswordResetRequestResultDto> resend({
    required String operationId,
  }) =>
      _request('resend_password_reset_operation_by_email', {
        'p_operation_id': operationId,
      });

  @override
  Future<PasswordResetVerifyResultDto> verify({
    required String operationId,
    required String code,
  }) async {
    try {
      final row = await _rpcClient.callMap(
        'verify_password_reset_code_by_email',
        params: {'p_operation_id': operationId, 'p_code': code},
      );
      return PasswordResetVerifyResultDto(
        verified: (row['verified'] as bool?) ?? false,
      );
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }

  @override
  Future<PasswordResetCompletionResultDto> complete({
    required String operationId,
    required String newPassword,
  }) async {
    try {
      final row = await _rpcClient.callMap(
        'complete_password_reset_operation_by_email',
        params: {
          'p_operation_id': operationId,
          'p_new_password': newPassword,
        },
      );
      return PasswordResetCompletionResultDto(
        currentSessionRotated: (row['current_session_rotated'] as bool?) ?? false,
        otherSessionsRevoked: (row['other_sessions_revoked'] as bool?) ?? true,
      );
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }

  Future<PasswordResetRequestResultDto> _request(
    String fn,
    Map<String, dynamic> params,
  ) async {
    try {
      final row = await _rpcClient.callMap(fn, params: params);
      return PasswordResetRequestResultDto(
        operationId: row['operation_id'] as String,
        maskedEmail: (row['masked_email'] as String?) ?? '***',
        expiresAt: DateTime.parse(row['expires_at'] as String),
        resendAvailableAt: DateTime.parse(row['resend_available_at'] as String),
      );
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }
}
