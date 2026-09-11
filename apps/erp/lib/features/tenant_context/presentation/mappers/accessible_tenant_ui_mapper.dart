import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_presentation/presentation.dart';

final class AccessibleTenantUiMapper {
  const AccessibleTenantUiMapper._();

  static SelectOrganizationItemUiModel fromDto(AccessibleTenantDto dto) {
    // Base rule: only active tenants are operational/selectable.
    // Owner exception: an owner may enter their own provisioning tenant to
    // complete activation (readiness → "Kích hoạt tổ chức") from within ERP.
    final isSelectable =
        dto.isSelectable || (dto.status == TenantLifecycleStatus.provisioning && dto.isOwner);

    return SelectOrganizationItemUiModel(
      id: dto.tenantId,
      name: dto.name,
      code: _codeFor(dto.tenantId),
      roleLabel: IamRoleLabelMapper.toDisplayLabel(dto.roleLabel),
      status: dto.status,
      isCurrent: dto.isCurrent,
      isSelectable: isSelectable,
    );
  }

  static List<SelectOrganizationItemUiModel> fromList(
    List<AccessibleTenantDto> dtos,
  ) {
    return dtos.map(fromDto).toList(growable: false);
  }

  static String _codeFor(String tenantId) {
    final compact = tenantId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (compact.isEmpty) return 'TEN-UNKNOWN';
    final suffix = compact.length <= 6
        ? compact.toUpperCase()
        : compact.substring(0, 6).toUpperCase();
    return 'TEN-$suffix';
  }
}
