import 'package:supabase/supabase.dart';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';

import 'models/my_account.dart';

class AccountRepository {
  AccountRepository({
    required SupabaseRpc rpc,
    required GoTrueClient auth,
  }) : _rpc = rpc,
       _auth = auth;

  final SupabaseRpc _rpc;
  final GoTrueClient _auth;

  Future<MyAccount> getMyAccount() {
    return _load('get_my_platform_user_profile');
  }

  Future<MyAccount> updateMyAccount({
    String? avatarReference,
    required String givenName,
    required String familyName,
    String? phone,
  }) {
    return _load(
      'update_my_platform_user_profile',
      params: {
        'p_avatar_reference': avatarReference,
        'p_given_name': givenName,
        'p_family_name': familyName,
        'p_phone': phone,
      },
    );
  }

  Future<MyAccount> _load(
    String fn, {
    Map<String, dynamic> params = const {},
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException(AppErrorCode.authRequired);
    }
    final row = await _rpc.firstRow('iam', fn, params: params);
    return MyAccount.fromProfileRow(
      row,
      email: user.email ?? '',
      emailVerified: user.emailConfirmedAt != null,
    );
  }
}
