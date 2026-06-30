import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/partner_list_state.dart';

class PartnerDetailMenu extends StatelessWidget {
  final PartnerItemModel partner;
  final bool canManageStatus;
  final bool canDelete;
  final ValueChanged<String>? onActionSelected;

  const PartnerDetailMenu({
    super.key,
    required this.partner,
    this.canManageStatus = false,
    this.canDelete = false,
    this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (partner.status == 'Đã xóa') {
      return const SizedBox.shrink();
    }

    final dynamicColors = context.vColors;

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: dynamicColors.textPrimary),
      color: dynamicColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VRadius.card),
        side: BorderSide(color: dynamicColors.borderDefault),
      ),
      onSelected: onActionSelected,
      itemBuilder: (BuildContext context) {
        final items = <PopupMenuEntry<String>>[];

        if (canManageStatus && partner.status == 'Đang hoạt động') {
          items.add(
            PopupMenuItem<String>(
              value: 'deactivate',
              child: Text(
                'Ngừng hoạt động',
                style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
              ),
            ),
          );
        } else if (canManageStatus && partner.status == 'Ngừng hoạt động') {
          items.add(
            PopupMenuItem<String>(
              value: 'activate',
              child: Text(
                'Kích hoạt lại',
                style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
              ),
            ),
          );
        }

        if (canDelete) {
          items.add(
            PopupMenuItem<String>(
              value: 'delete',
              child: Text(
                'Xóa hồ sơ',
                style: VTypography.bodyDefault.copyWith(color: VColors.danger),
              ),
            ),
          );
        }

        return items;
      },
    );
  }
}
