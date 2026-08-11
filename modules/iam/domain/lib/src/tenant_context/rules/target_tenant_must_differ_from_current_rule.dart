import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// EP-05/US-02 BR-02 — target must differ from current tenant when current exists.
final class TargetTenantMustDifferFromCurrentRule implements IBusinessRule {
  const TargetTenantMustDifferFromCurrentRule({
    required this.targetTenantId,
    this.currentTenantId,
  });

  final String targetTenantId;
  final String? currentTenantId;

  @override
  bool isBroken() {
    final current = currentTenantId?.trim();
    if (current == null || current.isEmpty) {
      return false;
    }
    return targetTenantId.trim() == current;
  }

  @override
  String get message =>
      'Target tenant must differ from the current tenant context';
}
