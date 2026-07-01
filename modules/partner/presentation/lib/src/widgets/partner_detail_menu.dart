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

  void _showBottomSheet(BuildContext context) {
    final dynamicColors = context.vColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: dynamicColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VRadius.sheet),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.space4,
                    vertical: VSpacing.space3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hành động',
                        style: VTypography.headingH3.copyWith(
                          color: dynamicColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(bottomSheetContext).pop(),
                        child: Icon(Icons.close, color: dynamicColors.textPrimary, size: 24),
                      ),
                    ],
                  ),
                ),
                Divider(color: dynamicColors.borderDefault, height: 1),
                const SizedBox(height: VSpacing.space2),
                if (canManageStatus && partner.status == 'Đang hoạt động')
                  _buildActionItem(
                    context: bottomSheetContext,
                    icon: Icons.pause_circle_outline,
                    label: 'Ngừng hoạt động',
                    color: dynamicColors.textPrimary,
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      onActionSelected?.call('deactivate');
                    },
                  )
                else if (canManageStatus && partner.status == 'Ngừng hoạt động')
                  _buildActionItem(
                    context: bottomSheetContext,
                    icon: Icons.play_circle_outline,
                    label: 'Kích hoạt lại',
                    color: dynamicColors.textPrimary,
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      onActionSelected?.call('activate');
                    },
                  ),
                if (canDelete)
                  _buildActionItem(
                    context: bottomSheetContext,
                    icon: Icons.delete_outline,
                    label: 'Xóa KH & NCC',
                    color: VColors.danger,
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      onActionSelected?.call('delete');
                    },
                  ),
                const SizedBox(height: VSpacing.space4),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space4,
          vertical: VSpacing.space3,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: VSpacing.space3),
            Text(
              label,
              style: VTypography.bodyDefault.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (partner.status == 'Đã xóa') {
      return const SizedBox.shrink();
    }

    final dynamicColors = context.vColors;

    return IconButton(
      icon: Icon(Icons.more_horiz, color: dynamicColors.textPrimary),
      onPressed: onActionSelected == null ? null : () => _showBottomSheet(context),
    );
  }
}
