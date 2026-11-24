import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import 'package:erp/features/partner/logic/partner_error_messages.dart';
import 'package:erp/features/partner/presentation.dart';

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
  required PartnerRepository repository,
  required PartnerStatusCubit statusCubit,
  required PartnerDetailDto dto,
}) async {
  try {
    final eligibility = await repository.checkDeleteEligibility(dto.partnerId);
    if (!context.mounted) return PartnerSoftDeleteFlowResult.done;
    if (!eligibility.eligible) {
      final canDeactivate =
          dto.status == PartnerStatus.active &&
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
  } catch (error) {
    if (!context.mounted) return PartnerSoftDeleteFlowResult.done;
    VToast.show(
      context,
      title: 'Không thành công',
      message: partnerErrorMessage(
        error,
        fallback: 'Không kiểm tra được điều kiện xóa. Vui lòng thử lại.',
        noPermission: 'Bạn không có quyền xóa hồ sơ.',
      ),
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
