import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../shared/detail_layout.dart';
import '../models/user_ui_model.dart';

class InvitationDetailNarrow extends StatelessWidget {
  const InvitationDetailNarrow({
    super.key,
    required this.invitation,
    required this.statusLabel,
    required this.statusTone,
  });

  final InvitationUiModel invitation;
  final String statusLabel;
  final VComponentTone statusTone;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        DetailHeaderNarrow(
          leading: const DetailIconTile(VIcons.mail),
          title: invitation.email,
          subtitle:
              invitation.expiryLabel.isEmpty ? null : invitation.expiryLabel,
        ),
        const VGap.md(),
        DetailSectionNarrow(
          title: 'Thông tin lời mời',
          children: [
            DetailRow(label: 'Vai trò ban đầu', value: invitation.role),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: VText(
                    'Trạng thái',
                    variant: VTextVariant.bodyDefault,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                VBadge(
                  label: statusLabel,
                  tone: statusTone,
                  variant: VBadgeVariant.soft,
                  isSmall: true,
                ),
              ],
            ),
            DetailRow(
              label: 'Giao nhận',
              value: invitation.deliveryLabel.isEmpty
                  ? '—'
                  : invitation.deliveryLabel,
            ),
          ],
        ),
      ],
    );
  }
}
