import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_blocked_error_mapper.dart';

/// Password-reset operation metadata (§S14).
///
/// NEVER carries the recovery code (or a hash of it) — only lifecycle status
/// and timing. The raw code lives exclusively inside Supabase Auth.
final class PasswordResetOperation {
  const PasswordResetOperation({
    required this.operationId,
    required this.userId,
    required this.status,
    required this.expiresAt,
    required this.resendAvailableAt,
  });

  final String operationId;
  final String userId;
  final String status; // pending | verified | completed
  final DateTime expiresAt;
  final DateTime resendAvailableAt;
}

/// Persists password-reset operation metadata (no secret material).
abstract interface class PasswordResetOperationStore {
  Future<PasswordResetOperation> begin();

  Future<PasswordResetOperation> get(String operationId);

  Future<PasswordResetOperation> touchResend(String operationId);

  /// Verifies [code] against the stored hash for [operationId].
  /// Returns whether the code matched; raises [IamBlockedException] for
  /// expired / attempts-exceeded / not-found / completed states.
  Future<bool> verifyCode(String operationId, String code);

  Future<void> markVerified(String operationId);

  Future<void> markCompleted(String operationId);
}

/// Supabase RPC-backed operation store over `iam.password_reset_operations`.
final class SupabasePasswordResetOperationStore
    implements PasswordResetOperationStore {
  SupabasePasswordResetOperationStore({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<PasswordResetOperation> begin() =>
      _callReturning('begin_password_reset_operation');

  @override
  Future<PasswordResetOperation> get(String operationId) => _callReturning(
    'get_password_reset_operation',
    params: {'p_operation_id': operationId},
  );

  @override
  Future<PasswordResetOperation> touchResend(String operationId) =>
      _callReturning(
        'resend_password_reset_operation',
        params: {'p_operation_id': operationId},
      );

  @override
  Future<bool> verifyCode(String operationId, String code) async {
    try {
      final row = await _rpcClient.callMap(
        'verify_password_reset_code',
        params: {'p_operation_id': operationId, 'p_code': code},
      );
      return (row['verified'] as bool?) ?? false;
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }

  @override
  Future<void> markVerified(String operationId) => _callVoid(
    'mark_password_reset_operation_verified',
    params: {'p_operation_id': operationId},
  );

  @override
  Future<void> markCompleted(String operationId) => _callVoid(
    'mark_password_reset_operation_completed',
    params: {'p_operation_id': operationId},
  );

  Future<PasswordResetOperation> _callReturning(
    String fn, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final row = await _rpcClient.callMap(fn, params: params);
      return PasswordResetOperation(
        operationId: row['operation_id'] as String,
        userId: row['user_id'] as String,
        status: (row['status'] as String?) ?? 'pending',
        expiresAt: DateTime.parse(row['expires_at'] as String),
        resendAvailableAt: DateTime.parse(row['resend_available_at'] as String),
      );
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }

  Future<void> _callVoid(String fn, {Map<String, dynamic>? params}) async {
    try {
      await _rpcClient.callMap(fn, params: params);
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }
}
