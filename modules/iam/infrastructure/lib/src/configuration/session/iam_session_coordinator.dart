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
  SessionDto get snapshot =>
      _session.toDto(email: _authenticator.currentEmail);

  @override
  Future<void> establishAfterSignIn({String? tenantId}) async {
    if (_authenticator.currentUserId == null) {
      throw ApplicationException('Not authenticated');
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

    var context = await _accessGateway.getSessionContext(tenantId: tenantId);
    if (context == null) {
      final bootstrappedTenantId = await _accessGateway.bootstrapOwner();
      context = await _accessGateway.getSessionContext(
        tenantId: bootstrappedTenantId,
      );
    }

    if (context == null) {
      throw ApplicationException('Failed to establish IAM session');
    }

    _session.apply(context);
  }

  @override
  Future<void> clear() async {
    _session.clear();
  }

  @override
  Future<void> restoreFromPersistedAuth() async {
    if (_authenticator.currentUserId == null) {
      _session.clear();
      return;
    }

    try {
      var context = await _accessGateway.getSessionContext();
      if (context == null) {
        final bootstrappedTenantId = await _accessGateway.bootstrapOwner();
        context = await _accessGateway.getSessionContext(
          tenantId: bootstrappedTenantId,
        );
      }

      if (context != null) {
        _session.apply(context);
      } else {
        _session.clear();
      }
    } on ApplicationException {
      _session.clear();
    }
  }
}
