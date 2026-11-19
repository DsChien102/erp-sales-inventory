import 'package:flutter/material.dart';
import '../../data/models.dart';
import 'package:c45_design_system/design_system.dart';

class ProductControlCenterDangerSection extends StatefulWidget {
  final ProductBusinessStatus businessStatus;
  final bool isSoftDeleted;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;
  final VoidCallback onDelete;
  final VoidCallback onRestore;

  const ProductControlCenterDangerSection({
    super.key,
    required this.businessStatus,
    required this.isSoftDeleted,
    required this.onDeactivate,
    required this.onReactivate,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  State<ProductControlCenterDangerSection> createState() =>
      _ProductControlCenterDangerSectionState();
}

class _ProductControlCenterDangerSectionState extends State<ProductControlCenterDangerSection> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            duration: VDuration.medium,
            curve: Curves.easeInOut,
            alignment: 1.0,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isActive = widget.businessStatus == ProductBusinessStatus.active;
    final subtitle = widget.isSoftDeleted
        ? 'Khôi phục sản phẩm'
        : 'Ngừng kinh doanh · Xoá sản phẩm';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          key: const Key('btn_product_lifecycle_danger_toggle'),
          onTap: _toggleExpanded,
          child: Container(
            padding: const EdgeInsets.all(VSpacing.md),
            decoration: BoxDecoration(
              color: dynamicColors.dangerBg,
              border: Border.all(
                color: dynamicColors.danger.withValues(alpha: 0.3),
              ),
              borderRadius: _isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(VRadius.r12))
                  : BorderRadius.circular(VRadius.r12),
            ),
            child: Row(
              children: [
                VIconBox(
                  icon: VIcons.error,
                  size: 40,
                  iconSize: 20,
                  backgroundColor: dynamicColors.surface,
                  iconColor: dynamicColors.danger,
                ),
                const VGap.horizontalMd(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        'Nâng cao',
                        variant: VTextVariant.bodyDefault,
                        color: dynamicColors.danger,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const VGap.xs(),
                      VText(
                        subtitle,
                        variant: VTextVariant.bodySmall,
                        color: dynamicColors.danger,
                      ),
                    ],
                  ),
                ),
                VIcon(
                  icon: _isExpanded ? VIcons.expandLess : VIcons.expandMore,
                  color: dynamicColors.danger,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            decoration: BoxDecoration(
              color: dynamicColors.surface,
              border: Border(
                left: BorderSide(color: dynamicColors.danger.withValues(alpha: 0.3)),
                right: BorderSide(color: dynamicColors.danger.withValues(alpha: 0.3)),
                bottom: BorderSide(color: dynamicColors.danger.withValues(alpha: 0.3)),
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(VRadius.r12)),
            ),
            child: Column(
              children: [
                if (widget.isSoftDeleted)
                  _ActionItem(
                    icon: VIcons.restore,
                    label: 'Khôi phục',
                    color: dynamicColors.danger,
                    onTap: widget.onRestore,
                  )
                else if (isActive)
                  _ActionItem(
                    icon: VIcons.ban,
                    label: 'Ngừng kinh doanh',
                    color: dynamicColors.danger,
                    onTap: widget.onDeactivate,
                  )
                else
                  _ActionItem(
                    icon: VIcons.play,
                    label: 'Kinh doanh lại',
                    color: dynamicColors.danger,
                    onTap: widget.onReactivate,
                  ),
                if (!widget.isSoftDeleted) ...[
                  Divider(
                    height: 1,
                    color: dynamicColors.danger.withValues(alpha: 0.1),
                    indent: VSpacing.md,
                    endIndent: VSpacing.md,
                  ),
                  _ActionItem(
                    icon: VIcons.delete,
                    label: 'Xoá sản phẩm',
                    color: dynamicColors.danger,
                    onTap: widget.onDelete,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final VIcons icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.md,
        ),
        child: Row(
          children: [
            VIcon(icon: icon, color: color, size: 20),
            const VGap.horizontalMd(),
            Expanded(
              child: VText(
                label,
                variant: VTextVariant.bodyDefault,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
