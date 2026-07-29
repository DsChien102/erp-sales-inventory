import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_error_mapper.dart';

/// Supabase RPC adapter for EP-06 Identity self-service.
final class SupabaseIdentitySelfServiceGateway
    implements IIdentitySelfServiceGateway {
  SupabaseIdentitySelfServiceGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<MyIdentityProfileDto> getMyIdentityProfile() async {
    try {
      final result = await _rpcClient.callMap(
        'get_my_identity_profile',
        params: const <String, dynamic>{},
      );
      if (result.isEmpty) {
        throw ApplicationException('SYSTEM_ERROR');
      }
      return _mapProfile(result);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<MyIdentityProfileDto> updateMyIdentityProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    try {
      final result = await _rpcClient.callMap(
        'update_my_identity_profile',
        params: <String, dynamic>{
          'p_first_name': firstName,
          'p_last_name': lastName,
          'p_phone_number': phoneNumber,
          'p_avatar_url': avatarUrl,
        },
      );
      return _mapProfile(result);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<PasswordResetOperationDto> requestMyPasswordReset() async {
    try {
      final result = await _rpcClient.callMap(
        'request_my_password_reset',
        params: const <String, dynamic>{},
      );
      return _mapOperation(result);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<PasswordResetOperationDto> resendMyPasswordReset({
    required String operationId,
  }) async {
    try {
      final result = await _rpcClient.callMap(
        'resend_my_password_reset',
        params: <String, dynamic>{'p_operation_id': operationId},
      );
      return _mapOperation(result);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> verifyMyPasswordReset({
    required String operationId,
    required String code,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'verify_my_password_reset',
        params: <String, dynamic>{
          'p_operation_id': operationId,
          'p_code': code,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> completeMyPasswordReset({
    required String operationId,
    required String newPassword,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'complete_my_password_reset',
        params: <String, dynamic>{
          'p_operation_id': operationId,
          'p_new_password': newPassword,
        },
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  MyIdentityProfileDto _mapProfile(Map<String, dynamic> row) {
    return MyIdentityProfileDto(
      userId: row['user_id'] as String? ?? '',
      firstName: row['first_name'] as String? ?? '',
      lastName: row['last_name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      emailVerified: row['email_verified'] as bool? ?? false,
      phoneNumber: row['phone_number'] as String?,
      avatarUrl: row['avatar_url'] as String?,
    );
  }

  PasswordResetOperationDto _mapOperation(Map<String, dynamic> row) {
    return PasswordResetOperationDto(
      operationId: row['operation_id'] as String? ?? '',
      maskedEmail: row['masked_email'] as String? ?? '',
      expiresAt: row['expires_at'] == null
          ? null
          : DateTime.tryParse(row['expires_at'].toString()),
      resendAfterSeconds: row['resend_after_seconds'] as int?,
    );
  }
}
