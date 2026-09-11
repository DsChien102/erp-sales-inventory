import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:erp/features/partner/presentation.dart';
import 'package:vet45_shared_application/application.dart';

/// Soft-delete flow outcome for the detail page.
enum PartnerSoftDeleteFlowResult {
  /// Cancelled, blocked dismissed, or delete submitted (cubit handles success).
  done,

  /// User chose «Ngừng hoạt động» from D-09 blocked sheet.
  openDeactivate,
}

/// Eligibility check + soft-delete confirmation → [PartnerStatusCubit.softDelete].
Future<PartnerSoftDeleteFlowResult> runPartnerDetailSoftDeleteFlow({
  required BuildContext context,
  required IPartnerModule partnerModule,
  required IExecutionContext executionContext,
  required PartnerStatusCubit statusCubit,
  required PartnerDetailDto dto,
}) async {
  try {
    final tenantId = await executionContext.requireTenantId();
    final eligibility =
        await partnerModule.executeQueryAsync<DeleteEligibilityDto>(
      CheckDeleteEligibilityQuery(
        tenantId: tenantId,
        partnerId: dto.partnerId,
      ),
    );
    if (!context.mounted) return PartnerSoftDeleteFlowResult.done;
    if (!eligibility.eligible) {
      final canDeactivate = dto.status == PartnerStatus.active &&
          dto.availableActions.contains(PartnerAvailableAction.deactivate);
      final blocked = await showPartnerDeleteBlockedSheet(
        context,
        showDeactivateAction: canDeactivate,
      );
      if (blocked == PartnerDeleteBlockedResult.deactivate) {
        return PartnerSoftDeleteFlowResult.openDeactivate;
      }
      return PartnerSoftDeleteFlowResult.done;
    }
  } on PartnerBlockedException catch (error) {
    if (!context.mounted) return PartnerSoftDeleteFlowResult.done;
    VToast.show(
      context,
      title: 'Không thành công',
      message: error.code == PartnerBlockedCodes.noPermission
          ? 'Bạn không có quyền xóa hồ sơ.'
          : (error.message ?? 'Không kiểm tra được điều kiện xóa.'),
      type: VToastType.danger,
    );
    return PartnerSoftDeleteFlowResult.done;
  } catch (_) {
    if (!context.mounted) return PartnerSoftDeleteFlowResult.done;
    VToast.show(
      context,
      title: 'Không thành công',
      message: 'Không kiểm tra được điều kiện xóa. Vui lòng thử lại.',
      type: VToastType.danger,
    );
    return PartnerSoftDeleteFlowResult.done;
  }

  final reason = await showPartnerSoftDeleteConfirmationSheet(context);
  if (reason == null || !context.mounted) {
    return PartnerSoftDeleteFlowResult.done;
  }
  await statusCubit.softDelete(
    partnerId: dto.partnerId,
    expectedVersion: dto.expectedVersion,
    reason: reason.isEmpty ? null : reason,
  );
  return PartnerSoftDeleteFlowResult.done;
}
