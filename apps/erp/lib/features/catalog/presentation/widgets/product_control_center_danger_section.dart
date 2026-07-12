import 'package:flutter/material.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_design_system/design_system.dart';

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
            duration: const Duration(milliseconds: 300),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dynamicColors.dangerBg,
              border: Border.all(
                color: dynamicColors.danger.withValues(alpha: 0.3),
              ),
              borderRadius: _isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                VIconBox(
                  iconData: Icons.error_outline,
                  size: 40,
                  iconSize: 20,
                  backgroundColor: dynamicColors.surface,
                  iconColor: dynamicColors.danger,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nâng cao',
                        style: VTypography.bodyDefault.copyWith(
                          color: dynamicColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: VTypography.bodySmall.copyWith(
                          color: dynamicColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
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
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(
              children: [
                if (widget.isSoftDeleted)
                  _ActionItem(
                    icon: Icons.restore_outlined,
                    label: 'Khôi phục',
                    color: dynamicColors.danger,
                    onTap: widget.onRestore,
                  )
                else if (isActive)
                  _ActionItem(
                    icon: Icons.do_not_disturb_alt,
                    label: 'Ngừng kinh doanh',
                    color: dynamicColors.danger,
                    onTap: widget.onDeactivate,
                  )
                else
                  _ActionItem(
                    icon: Icons.play_arrow_outlined,
                    label: 'Kinh doanh lại',
                    color: dynamicColors.danger,
                    onTap: widget.onReactivate,
                  ),
                if (!widget.isSoftDeleted) ...[
                  Divider(
                    height: 1,
                    color: dynamicColors.danger.withValues(alpha: 0.1),
                    indent: 16,
                    endIndent: 16,
                  ),
                  _ActionItem(
                    icon: Icons.delete_outline,
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
  final IconData icon;
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: VTypography.bodyDefault.copyWith(
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
