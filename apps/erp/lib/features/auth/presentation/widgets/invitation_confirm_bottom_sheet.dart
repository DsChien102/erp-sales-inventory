import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/invitation_token_inspection.dart';

/// Hiển thị Bottom Sheet xác nhận lời mời khi tài khoản đã tồn tại.
///
/// Trả về `true` nếu bấm Xác nhận, `false` nếu bấm Từ chối, `null` nếu đóng sheet.
Future<bool?> showInvitationConfirmBottomSheet({
  required BuildContext context,
  required InvitationTokenInspection inspection,
}) {
  return showVBottomSheet<bool>(
    context: context,
    child: _InvitationConfirmSheetContent(inspection: inspection),
  );
}

class _InvitationConfirmSheetContent extends StatelessWidget {
  const _InvitationConfirmSheetContent({required this.inspection});

  final InvitationTokenInspection inspection;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: VText(
              'Xác nhận lời mời tham gia tổ chức?',
              variant: VTextVariant.headingH3,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          const VGap.sm(),
          VText(
            'Mã lời mời hợp lệ.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.md(),
          _InfoRow(label: 'Tổ chức', value: inspection.tenantName),
          _InfoRow(label: 'Vai trò', value: inspection.initialRoleLabel),
          _InfoRow(label: 'Email', value: inspection.inviteeEmail),
          const VGap.xl(),
          VButton(
            key: const Key('invitation_confirm_sheet_accept'),
            label: 'Xác nhận',
            variant: VButtonVariant.primary,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const VGap.md(),
          VButton(
            key: const Key('invitation_confirm_sheet_decline'),
            label: 'Từ chối',
            variant: VButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const VGap.sm(),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: VSpacing.space1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: VText(
                label,
                variant: VTextVariant.bodySmall,
                color: context.vColors.textSecondary,
              ),
            ),
            Expanded(child: VText(value, variant: VTextVariant.labelDefault)),
          ],
        ),
      ),
    );
  }
}
