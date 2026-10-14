import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/warehouse_manual_action.dart';

class WarehouseStartNewSheet extends StatelessWidget {
  const WarehouseStartNewSheet({
    super.key,
    required this.actions,
    this.onSelectAction,
  });

  final List<WarehouseManualAction> actions;
  final ValueChanged<WarehouseManualAction>? onSelectAction;

  static Future<void> show(
    BuildContext context, {
    required List<WarehouseManualAction> actions,
    ValueChanged<WarehouseManualAction>? onSelectAction,
  }) {
    return showVBottomSheet(
      context: context,
      title: 'Bắt đầu việc mới',
      child: WarehouseStartNewSheet(
        actions: actions,
        onSelectAction: onSelectAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.only(
        left: VSpacing.screenMobile,
        right: VSpacing.screenMobile,
        bottom: VSpacing.space6,
        top: VSpacing.space2,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(height: VSpacing.space2),
        itemBuilder: (context, index) {
          final action = actions[index];
          return Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(VRadius.card),
              border: Border.all(
                color: colors.borderDefault,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(VRadius.card),
                onTap: () {
                  Navigator.of(context).pop();
                  onSelectAction?.call(action);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.space4,
                    vertical: VSpacing.space3,
                  ),
                  child: Row(
                    children: [
                      VIcon(
                        icon: action.icon,
                        iconSize: VIconSize.md,
                        iconColor: VIconColor.secondary,
                      ),
                      const SizedBox(width: VSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VText(
                              action.title,
                              style: VTypography.labelDefault.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            VText(
                              action.subtitle,
                              style: VTypography.caption.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const VIcon(
                        icon: VIcons.chevronRight,
                        iconSize: VIconSize.sm,
                        iconColor: VIconColor.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
