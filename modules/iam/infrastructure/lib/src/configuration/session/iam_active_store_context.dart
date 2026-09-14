import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'iam_session.dart';

/// Resolves active store from the in-memory session, refreshing once from IAM
/// when the snapshot was established before store context existed.
final class IamActiveStoreContext implements IActiveStoreContext {
  IamActiveStoreContext({
    required IamSession session,
    required IIamAccessGateway accessGateway,
  }) : _session = session,
       _accessGateway = accessGateway;

  final IamSession _session;
  final IIamAccessGateway _accessGateway;
  Future<void>? _refreshInFlight;

  @override
  String? get activeStoreId => _session.activeStoreId;

  @override
  Future<String> requireActiveStoreId() async {
    final current = _session.activeStoreId?.trim();
    if (current != null && current.isNotEmpty) {
      return current;
    }

    await _refreshActiveStore();
    return _session.requireActiveStoreId();
  }

  Future<void> _refreshActiveStore() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final future = _doRefresh();
    _refreshInFlight = future;
    try {
      await future;
    } finally {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<void> _doRefresh() async {
    final tenantId = _session.tenantId?.trim();
    if (tenantId == null || tenantId.isEmpty) {
      // Multi-tenant: never call get_session_context without an explicit tenant.
      throw ApplicationException('Tenant context is required.');
    }

    final context = await _accessGateway.getSessionContext(tenantId: tenantId);
    if (context == null) {
      throw ApplicationException('Active store context is required.');
    }
    _session.apply(context);
  }
}
