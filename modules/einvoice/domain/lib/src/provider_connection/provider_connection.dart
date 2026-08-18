import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'provider_code.dart';
import 'provider_connection_status.dart';
import 'provider_connection_id.dart';
import '../shared/rules/predicate_business_rule.dart';
import 'rules/provider_connection_status_transition_allowed_rule.dart';
import 'provider_capabilities_snapshot.dart';

/// ProviderConnection aggregate — tenant-scoped MISA connection lifecycle.
final class ProviderConnection extends Entity<ProviderConnectionId>
    implements IAggregateRoot {
  ProviderConnection._({
    required super.id,
    required TenantId tenantId,
    required ProviderCode providerCode,
    required ProviderConnectionStatus status,
    ProviderCapabilitiesSnapshot? capabilitiesSnapshot,
    DateTime? lastVerifiedAt,
    required int connectionVersion,
  }) : _tenantId = tenantId,
       _providerCode = providerCode,
       _status = status,
       _capabilitiesSnapshot = capabilitiesSnapshot,
       _lastVerifiedAt = lastVerifiedAt,
       _connectionVersion = connectionVersion;

  final TenantId _tenantId;
  final ProviderCode _providerCode;
  ProviderConnectionStatus _status;
  ProviderCapabilitiesSnapshot? _capabilitiesSnapshot;
  DateTime? _lastVerifiedAt;
  int _connectionVersion;

  TenantId get tenantId => _tenantId;
  ProviderCode get providerCode => _providerCode;
  ProviderConnectionStatus get status => _status;
  ProviderCapabilitiesSnapshot? get capabilitiesSnapshot =>
      _capabilitiesSnapshot;
  DateTime? get lastVerifiedAt => _lastVerifiedAt;
  int get connectionVersion => _connectionVersion;

  bool get isActive =>
      _status != ProviderConnectionStatus.disconnected;

  factory ProviderConnection.reconstitute({
    required ProviderConnectionId id,
    required TenantId tenantId,
    required ProviderCode providerCode,
    required ProviderConnectionStatus status,
    ProviderCapabilitiesSnapshot? capabilitiesSnapshot,
    DateTime? lastVerifiedAt,
    required int connectionVersion,
  }) {
    return ProviderConnection._(
      id: id,
      tenantId: tenantId,
      providerCode: providerCode,
      status: status,
      capabilitiesSnapshot: capabilitiesSnapshot,
      lastVerifiedAt: lastVerifiedAt,
      connectionVersion: connectionVersion,
    );
  }

  /// Pending verification after credential commit (async worker path).
  void markPendingVerification() {
    _transitionTo(ProviderConnectionStatus.checkRequired);
  }

  /// Worker verified auth + synced mandatory capabilities.
  void markVerified({
    required ProviderCapabilitiesSnapshot capabilities,
    required DateTime verifiedAt,
  }) {
    _capabilitiesSnapshot = capabilities;
    _lastVerifiedAt = verifiedAt;
    _transitionTo(ProviderConnectionStatus.connected);
  }

  /// Legal profile changed or admin requested re-check.
  void markCheckRequired() {
    if (_status == ProviderConnectionStatus.disconnected) {
      return;
    }
    _transitionTo(ProviderConnectionStatus.checkRequired);
  }

  /// Credential invalid — requires reconnect.
  void markReconnectRequired() {
    if (_status == ProviderConnectionStatus.disconnected) {
      return;
    }
    _transitionTo(ProviderConnectionStatus.reconnectRequired);
  }

  /// Admin disconnect — history preserved (DR-06).
  void disconnect({required bool confirm}) {
    checkRule(
      PredicateBusinessRule(
        predicate: !confirm,
        ruleMessage: 'Disconnect requires confirmation',
      ),
    );
    _transitionTo(ProviderConnectionStatus.disconnected);
  }

  void assertExpectedVersion(int? expectedVersion) {
    if (expectedVersion == null) {
      return;
    }
    checkRule(
      PredicateBusinessRule(
        predicate: expectedVersion != _connectionVersion,
        ruleMessage:
            'Connection version mismatch: expected $expectedVersion, '
            'actual $_connectionVersion',
      ),
    );
  }

  void _transitionTo(ProviderConnectionStatus to) {
    checkRule(
      ProviderConnectionStatusTransitionAllowedRule(from: _status, to: to),
    );
    _status = to;
    _connectionVersion += 1;
  }
}
