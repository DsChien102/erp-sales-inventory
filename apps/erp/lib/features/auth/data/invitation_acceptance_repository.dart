import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/iam/data/models/tenant_invitation.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';

import 'package:supabase/supabase.dart';

import 'models/invitation_token_inspection.dart';

/// RPC nhận / từ chối lời mời. Không cần tenant đang chọn.
class InvitationAcceptanceRepository {
  InvitationAcceptanceRepository({
    required SupabaseRpc rpc,
    required FunctionsClient functions,
  }) : _rpc = rpc,
       _functions = functions;

  final SupabaseRpc _rpc;
  final FunctionsClient _functions;

  Future<InvitationTokenInspection> inspect(String token) async {
    final result = await _rpc.call(
      'iam',
      'inspect_invitation_token',
      params: <String, dynamic>{'p_token': token},
    );
    return InvitationTokenInspection.fromJson(_asMap(result));
  }

  Future<TenantMemberDetail> accept(
    String token, {
    required String idempotencyKey,
  }) async {
    final result = await _rpc.call(
      'iam',
      'accept_invitation',
      params: <String, dynamic>{
        'p_token': token,
        'p_idempotency_key': idempotencyKey,
      },
    );
    return TenantMemberDetail.fromJson(_asMap(result));
  }

  /// Tạo tài khoản đã xác minh + nhận lời mời trong một lần (Edge Function `invitation-signup`).
  /// Mã lời mời đã được gửi tới đúng email được mời nên không cần mã xác minh 6 số.
  Future<TenantMemberDetail> registerAndAccept({
    required String token,
    required String password,
    required String givenName,
    required String familyName,
    String? phone,
    required String idempotencyKey,
  }) async {
    final FunctionResponse response;
    try {
      response = await _functions.invoke(
        'invitation-signup',
        body: <String, dynamic>{
          'token': token,
          'password': password,
          'given_name': givenName,
          'family_name': familyName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'idempotency_key': idempotencyKey,
        },
      );
    } on FunctionsFetchException catch (error) {
      throw AppException(AppErrorCode.network, cause: error);
    } on FunctionException catch (error) {
      throw _mapFunctionError(error);
    } catch (error, stackTrace) {
      throw AppException.from(error, stackTrace);
    }

    final data = response.data;
    final membership = data is Map ? data['membership'] : null;
    if (membership is! Map) {
      throw const AppException(AppErrorCode.unknown);
    }
    return TenantMemberDetail.fromJson(Map<String, dynamic>.from(membership));
  }

  Future<TenantInvitationDetail> decline(
    String token, {
    required String idempotencyKey,
  }) async {
    final result = await _rpc.call(
      'iam',
      'decline_invitation',
      params: <String, dynamic>{
        'p_token': token,
        'p_idempotency_key': idempotencyKey,
      },
    );
    return TenantInvitationDetail.fromJson(_asMap(result));
  }
}

AppException _mapFunctionError(FunctionException error) {
  final details = error.details;
  final code = details is Map ? details['code'] : null;
  if (code is! String || code.isEmpty) {
    return const AppException(AppErrorCode.unknown);
  }
  return switch (code) {
    'ACCOUNT_EXISTS' => const AppException('PLATFORM_USER_ALREADY_EXISTS'),
    'WEAK_PASSWORD' => const AppException('PASSWORD_POLICY_VIOLATION'),
    _ => AppException(code),
  };
}

Map<String, dynamic> _asMap(dynamic result) {
  if (result is Map) return Map<String, dynamic>.from(result);
  if (result is List && result.isNotEmpty && result.first is Map) {
    return Map<String, dynamic>.from(result.first as Map);
  }
  return const {};
}
