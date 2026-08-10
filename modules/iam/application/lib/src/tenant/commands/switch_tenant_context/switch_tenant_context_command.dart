import 'package:vet45_shared_application/application.dart';

import '../../shared/tenant_context_dto.dart';

/// Switches the actor's TenantContext after server-side access re-validation
/// (EP-05/US-02). Not tenant-scoped — target is [targetTenantId].
///
/// Confirmation dialog is presentation-only (FR-02); dispatch implies confirm.
///
/// Errors (BE): TENANT_ACCESS_DENIED, TENANT_SUSPENDED, TENANT_CLOSED.
final class SwitchTenantContextCommand extends CommandBase<TenantContextDto>
    implements ICommand<TenantContextDto> {
  SwitchTenantContextCommand({
    String? id,
    required this.targetTenantId,
  }) : super(id);

  final String targetTenantId;
}
