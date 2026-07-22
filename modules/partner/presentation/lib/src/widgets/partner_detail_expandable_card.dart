import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Expandable detail section card (tap header để mở/đóng).
class PartnerDetailExpandableCard extends StatefulWidget {
  const PartnerDetailExpandableCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailingWhenCollapsed,
    this.initiallyExpanded = false,
    this.onTap,
  });

  final String title;
  final VIcons icon;
  final Widget child;
  final Widget? trailingWhenCollapsed;
  final bool initiallyExpanded;
  final VoidCallback? onTap;

  @override
  State<PartnerDetailExpandableCard> createState() => _PartnerDetailExpandableCardState();
}

class _PartnerDetailExpandableCardState extends State<PartnerDetailExpandableCard> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(VRadius.card),
      side: BorderSide(color: colors.borderDefault),
    );

    return Material(
      color: colors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space4,
              vertical: 0,
            ),
            leading: VIcon(icon: widget.icon, color: colors.textSecondary, size: 20),
            title: VText(
              widget.title,
              variant: VTextVariant.bodyDefault,
              color: colors.textPrimary,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_expanded && widget.trailingWhenCollapsed != null) ...[
                  widget.trailingWhenCollapsed!,
                  const SizedBox(width: VSpacing.space1),
                ],
                VIcon(
                  icon: _expanded ? VIcons.expandLess : VIcons.chevronRight,
                  color: colors.textMuted,
                ),
              ],
            ),
            onTap: widget.onTap ?? _toggle,
          ),
          if (_expanded) ...[
            Divider(color: colors.borderDefault, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.space4,
                VSpacing.space3,
                VSpacing.space4,
                VSpacing.space3,
              ),
              child: widget.child,
            ),
          ],
        ],
      ),
    );
  }
}
