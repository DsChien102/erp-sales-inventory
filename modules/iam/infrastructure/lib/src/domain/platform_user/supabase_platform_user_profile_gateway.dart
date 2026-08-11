import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_blocked_error_mapper.dart';

/// Infrastructure-internal snapshot of the IAM-owned platform user profile.
///
/// Deliberately excludes login email / verified state — those come from
/// Supabase Auth and are joined by [SupabasePlatformIdentitySelfServiceAdapter].
final class PlatformUserProfileSnapshot {
  const PlatformUserProfileSnapshot({
    required this.userId,
    required this.givenName,
    required this.familyMiddleName,
    required this.phoneNumber,
    required this.avatarReference,
    required this.status,
  });

  final String userId;
  final String? givenName;
  final String? familyMiddleName;
  final String? phoneNumber;
  final String? avatarReference;
  final String status;
}

/// IAM-owned platform-user profile access (self-only).
abstract interface class PlatformUserProfileGateway {
  Future<PlatformUserProfileSnapshot> getMyProfile();

  Future<PlatformUserProfileSnapshot> updateMyProfile({
    required String? avatarReference,
    required String givenName,
    required String familyName,
    required String? phone,
  });
}

/// Reads/writes the IAM-owned `iam.platform_user_profiles` table via RPC.
///
/// Self-only: the user is always resolved from `auth.uid()` inside the RPC,
/// never passed from the client.
final class SupabasePlatformUserProfileGateway
    implements PlatformUserProfileGateway {
  SupabasePlatformUserProfileGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<PlatformUserProfileSnapshot> getMyProfile() async {
    try {
      final result = await _rpcClient.callMap('get_my_platform_user_profile');
      return _mapSnapshot(result);
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }

  @override
  Future<PlatformUserProfileSnapshot> updateMyProfile({
    required String? avatarReference,
    required String givenName,
    required String familyName,
    required String? phone,
  }) async {
    try {
      final result = await _rpcClient.callMap(
        'update_my_platform_user_profile',
        params: <String, dynamic>{
          'p_avatar_reference': avatarReference,
          'p_given_name': givenName,
          'p_family_name': familyName,
          'p_phone': phone,
        },
      );
      return _mapSnapshot(result);
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }

  PlatformUserProfileSnapshot _mapSnapshot(Map<String, dynamic> row) {
    return PlatformUserProfileSnapshot(
      userId: row['user_id'] as String,
      givenName: row['given_name'] as String?,
      familyMiddleName: row['family_middle_name'] as String?,
      phoneNumber: row['phone_number'] as String?,
      avatarReference: row['avatar_reference'] as String?,
      status: (row['status'] as String?) ?? 'pending_activation',
    );
  }
}
