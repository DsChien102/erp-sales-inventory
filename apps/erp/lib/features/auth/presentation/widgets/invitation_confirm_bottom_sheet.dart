import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/config/wide_layout.dart';
import 'package:flutter/material.dart';

import '../../data/models/invitation_token_inspection.dart';

/// Hiển thị Bottom Sheet xác nhận lời mời khi tài khoản đã tồn tại.
///
/// Trả về `true` nếu bấm Xác nhận, `false` nếu bấm Từ chối, `null` nếu đóng sheet.
Future<bool?> showInvitationConfirmBottomSheet({
  required BuildContext context,
  required InvitationTokenInspection inspection,
}) {
  return showVAdaptiveSheet<bool>(
    context: context,
    child: _InvitationConfirmSheetContent(inspection: inspection),
  );
}

class _InvitationConfirmSheetContent extends StatelessWidget {
  const _InvitationConfirmSheetContent({required this.inspection});

  final InvitationTokenInspection inspection;

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        child: wide
            ? _WideConfirmContent(inspection: inspection)
            : _NarrowConfirmContent(inspection: inspection),
      ),
    );
  }
}

class _NarrowConfirmContent extends StatelessWidget {
  const _NarrowConfirmContent({required this.inspection});

  final InvitationTokenInspection inspection;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: VText(
            'Xác nhận lời mời tham gia tổ chức?',
            variant: VTextVariant.headingH2,
            color: colors.textPrimary,
            style: const TextStyle(
              fontSize: 20,
              height: 28 / 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const VGap.xs(),
        Row(
          children: [
            VIcon(icon: VIcons.success, size: 18, color: colors.success),
            const SizedBox(width: 6),
            Expanded(
              child: VText(
                'Mã lời mời hợp lệ.',
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const VGap.md(),
        Container(
          padding: const EdgeInsets.all(VSpacing.screenMobile),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(VRadius.card),
          ),
          child: Column(
            children: [
              _NarrowInfoRow(label: 'Tổ chức', value: inspection.tenantName),
              const SizedBox(height: 10),
              _NarrowInfoRow(
                label: 'Vai trò',
                value: inspection.initialRoleLabel,
              ),
              const SizedBox(height: 10),
              _NarrowInfoRow(label: 'Email', value: inspection.inviteeEmail),
            ],
          ),
        ),
        const SizedBox(height: 20),
        VButton(
          key: const Key('invitation_confirm_sheet_accept'),
          label: 'Xác nhận',
          variant: VButtonVariant.primary,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const VGap.sm(),
        VButton(
          key: const Key('invitation_confirm_sheet_decline'),
          label: 'Từ chối',
          variant: VButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

class _NarrowInfoRow extends StatelessWidget {
  const _NarrowInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            label,
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: VText(
              value,
              variant: VTextVariant.bodyDefault,
              color: colors.textPrimary,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _WideConfirmContent extends StatelessWidget {
  const _WideConfirmContent({required this.inspection});

  final InvitationTokenInspection inspection;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Column(
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
