import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'iam_session.dart';

final class IamSessionCoordinator implements IIamSessionPort {
  IamSessionCoordinator({
    required IamSession session,
    required IIamAccessGateway accessGateway,
    required IAuthenticator authenticator,
  }) : _session = session,
       _accessGateway = accessGateway,
       _authenticator = authenticator;

  final IamSession _session;
  final IIamAccessGateway _accessGateway;
  final IAuthenticator _authenticator;

  @override
  SessionDto get snapshot => _session.toDto(email: _authenticator.currentEmail);

  @override
  Future<void> establishAfterSignIn({
    String? tenantId,
    bool requireTenantContext = true,
  }) async {
    final currentUserId = _authenticator.currentUserId;
    if (currentUserId == null) {
      throw ApplicationException('Not authenticated');
    }

    if (!requireTenantContext && tenantId == null) {
      _session.applyAuthenticatedUser(currentUserId);
      return;
    }

    if (tenantId != null) {
      final context = await _accessGateway.getSessionContext(
        tenantId: tenantId,
      );
      if (context == null) {
        throw ApplicationException('Tenant access denied');
      }
      _session.apply(context);
      return;
    }

    await _ensureActiveMembershipOrSignOut(throwOnEmpty: true);

    final context = await _accessGateway.getSessionContext(tenantId: tenantId);
    if (context == null) {
      await _signOutAndThrowNoActiveMembership();
    } else {
      _session.apply(context);
    }
  }

  @override
  Future<void> clear() async {
    _session.clear();
  }

  @override
  Future<void> restoreFromPersistedAuth({
    bool requireTenantContext = true,
  }) async {
    final currentUserId = _authenticator.currentUserId;
    if (currentUserId == null) {
      _session.clear();
      return;
    }

    final hasMembership = await _ensureActiveMembershipOrSignOut(
      throwOnEmpty: false,
    );
    if (!hasMembership) {
      return;
    }

    if (!requireTenantContext) {
      _session.applyAuthenticatedUser(currentUserId);
      return;
    }

    try {
      final context = await _accessGateway.getSessionContext();
      if (context != null) {
        _session.apply(context);
      } else {
        _session.clear();
      }
    } on ApplicationException {
      _session.clear();
    }
  }

  /// Returns `false` when the actor has no active membership (already signed out).
  Future<bool> _ensureActiveMembershipOrSignOut({
    required bool throwOnEmpty,
  }) async {
    final tenants = await _accessGateway.listAccessibleTenants();
    if (tenants.isNotEmpty) {
      return true;
    }
    await _rejectNoActiveMembership(throwOnEmpty: throwOnEmpty);
    return false;
  }

  Future<Never> _signOutAndThrowNoActiveMembership() async {
    await _authenticator.signOut();
    _session.clear();
    throw const IamBlockedException(IamBlockedCodes.noActiveMembership);
  }

  Future<void> _rejectNoActiveMembership({required bool throwOnEmpty}) async {
    if (throwOnEmpty) {
      await _signOutAndThrowNoActiveMembership();
    }
    await _authenticator.signOut();
    _session.clear();
  }
}
