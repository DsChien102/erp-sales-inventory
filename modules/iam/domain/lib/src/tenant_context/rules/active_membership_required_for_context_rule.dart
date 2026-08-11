import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// D-04 — TenantContext requires an active membership for the actor.
final class ActiveMembershipRequiredForContextRule implements IBusinessRule {
  const ActiveMembershipRequiredForContextRule({
    required this.hasActiveMembership,
  });

  final bool hasActiveMembership;

  @override
  bool isBroken() => !hasActiveMembership;

  @override
  String get message =>
      'Active membership is required to establish tenant context';
}
