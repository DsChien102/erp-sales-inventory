import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Hiển thị Bottom Sheet xác nhận lời mời khi tài khoản đã tồn tại.
///
/// Trả về `true` nếu bấm Xác nhận, `false` nếu bấm Từ chối, `null` nếu đóng sheet.
Future<bool?> showInvitationConfirmBottomSheet({
  required BuildContext context,
}) {
  return showVBottomSheet<bool>(
    context: context,
    child: const _InvitationConfirmSheetContent(),
  );
}

class _InvitationConfirmSheetContent extends StatelessWidget {
  const _InvitationConfirmSheetContent();

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
          VText(
            'Xác nhận lời mời tham gia tổ chức?',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const VGap.sm(),
          VText(
            'Mã lời mời hợp lệ.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
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
