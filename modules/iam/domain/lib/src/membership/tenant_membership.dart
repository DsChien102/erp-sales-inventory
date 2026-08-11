import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'membership_status.dart';
import 'rules/membership_status_transition_allowed_rule.dart';
import 'rules/removed_membership_is_terminal_rule.dart';
import 'rules/role_must_be_assignable_on_reactivate_rule.dart';
import 'rules/sole_owner_protected_rule.dart';
import 'tenant_membership_id.dart';

/// TenantMembership aggregate — lifecycle status + version.
final class TenantMembership extends Entity<TenantMembershipId>
    implements IAggregateRoot {
  TenantMembership._({
    required super.id,
    required TenantId tenantId,
    required String userId,
    required String role,
    required bool isOwner,
    required MembershipStatus status,
    required int version,
  }) : _tenantId = tenantId,
       _userId = userId,
       _role = role,
       _isOwner = isOwner,
       _status = status,
       _version = version;

  final TenantId _tenantId;
  final String _userId;
  final String _role;
  final bool _isOwner;
  MembershipStatus _status;
  int _version;

  TenantId get tenantId => _tenantId;
  String get userId => _userId;
  String get role => _role;
  bool get isOwner => _isOwner;
  MembershipStatus get status => _status;
  int get version => _version;

  factory TenantMembership.reconstitute({
    required TenantMembershipId id,
    required TenantId tenantId,
    required String userId,
    required String role,
    required bool isOwner,
    required MembershipStatus status,
    required int version,
  }) {
    return TenantMembership._(
      id: id,
      tenantId: tenantId,
      userId: userId,
      role: role,
      isOwner: isOwner,
      status: status,
      version: version,
    );
  }

  void deactivate({required bool isSoleOwner}) {
    checkRule(RemovedMembershipIsTerminalRule(_status));
    checkRule(
      SoleOwnerProtectedRule(isOwner: _isOwner, isSoleOwner: isSoleOwner),
    );
    _transitionTo(MembershipStatus.inactive);
  }

  void reactivate({required bool roleAssignable}) {
    checkRule(RemovedMembershipIsTerminalRule(_status));
    checkRule(RoleMustBeAssignableOnReactivateRule(roleAssignable: roleAssignable));
    _transitionTo(MembershipStatus.active);
  }

  void remove({required bool isSoleOwner}) {
    checkRule(RemovedMembershipIsTerminalRule(_status));
    checkRule(
      SoleOwnerProtectedRule(isOwner: _isOwner, isSoleOwner: isSoleOwner),
    );
    _transitionTo(MembershipStatus.removed);
  }

  void _transitionTo(MembershipStatus to) {
    checkRule(
      MembershipStatusTransitionAllowedRule(from: _status, to: to),
    );
    _status = to;
    _version += 1;
  }
}
