import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _log = Logger('erp.owner_activation.client');

/// Thrown when activation fails. Opaque — the RPCs return generic errors
/// (no account enumeration), so the UI shows one message.
final class OwnerActivationClientException implements Exception {
  const OwnerActivationClientException();
}

/// Result of inspecting an activation code (before sign-in/sign-up).
final class OwnerActivationInspection {
  const OwnerActivationInspection({
    required this.valid,
    this.accountExists = false,
    this.email,
    this.givenName,
    this.familyName,
    this.phone,
  });

  final bool valid;

  /// Whether the invited email already has an account → log in instead of sign up.
  final bool accountExists;
  final String? email;
  final String? givenName;
  final String? familyName;
  final String? phone;
}

/// Owner activation, mirroring the tenant-invitation flow: inspect the code, then
/// (existing account) log in + accept, or (new account) sign up + accept. The
/// owner membership is created by the accept RPC.
abstract interface class OwnerActivationClient {
  Future<OwnerActivationInspection> inspect(String code);

  Future<void> activate({
    required String code,
    required String email,
    required String password,
    required bool accountExists,
    String? givenName,
    String? familyName,
    String? phone,
    required String idempotencyKey,
  });
}

/// Supabase-backed implementation: `inspect_owner_activation` RPC (anon) →
/// `auth.signUp` (creates account + session) → `accept_owner_activation` RPC.
final class SupabaseOwnerActivationClient implements OwnerActivationClient {
  SupabaseOwnerActivationClient(this._client);

  final SupabaseClient _client;

  @override
  Future<OwnerActivationInspection> inspect(String code) async {
    try {
      final res = await _client.rpc(
        'inspect_owner_activation',
        params: <String, dynamic>{'p_code': code},
      );
      final map = (res as Map).cast<String, dynamic>();
      return OwnerActivationInspection(
        valid: map['valid'] == true,
        accountExists: map['account_exists'] == true,
        email: map['invitee_email'] as String?,
        givenName: map['given_name'] as String?,
        familyName: map['family_name'] as String?,
        phone: map['phone'] as String?,
      );
    } catch (error, stackTrace) {
      _log.warning('Owner activation inspect failed', error, stackTrace);
      return const OwnerActivationInspection(valid: false);
    }
  }

  @override
  Future<void> activate({
    required String code,
    required String email,
    required String password,
    required bool accountExists,
    String? givenName,
    String? familyName,
    String? phone,
    required String idempotencyKey,
  }) async {
    try {
      // Establish a session: existing account logs in, new account signs up.
      final Session? session;
      if (accountExists) {
        _log.info('Owner activation sign-in started');
        final signIn = await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        session = signIn.session;
      } else {
        _log.info('Owner activation sign-up started');
        final signUp = await _client.auth.signUp(
          email: email,
          password: password,
          data: <String, dynamic>{
            if (givenName != null && givenName.isNotEmpty)
              'first_name': givenName,
            if (familyName != null && familyName.isNotEmpty)
              'last_name': familyName,
            if (phone != null && phone.isNotEmpty) 'phone': phone,
          },
        );
        session = signUp.session;
      }
      if (session == null) {
        _log.warning('Owner activation returned no session');
        throw const OwnerActivationClientException();
      }

      await _client.rpc(
        'accept_owner_activation',
        params: <String, dynamic>{
          'p_code': code,
          'p_idempotency_key': idempotencyKey,
        },
      );
      _log.info('Owner activation accepted');
    } on OwnerActivationClientException {
      rethrow;
    } catch (error, stackTrace) {
      _log.warning('Owner activation failed', error, stackTrace);
      throw const OwnerActivationClientException();
    }
  }
}
