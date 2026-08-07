import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class TodoItem extends StatelessWidget {
  final Widget leadingIcon;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final VBadgeStatus badgeStatus;
  final VoidCallback? onTap;
  final VComponentTone? tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  const TodoItem({
    super.key,
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeStatus,
    this.onTap,
    this.tone,
    this.emphasis = VComponentEmphasis.medium,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    Color iconBgColor;
    Color iconColor;

    switch (badgeStatus) {
      case VBadgeStatus.danger:
      case VBadgeStatus.overdue:
        iconBgColor = colors.dangerBg;
        iconColor = colors.danger;
        break;
      case VBadgeStatus.warning:
      case VBadgeStatus.partiallyPaid:
      case VBadgeStatus.outstanding:
        iconBgColor = colors.warningBg;
        iconColor = colors.warning;
        break;
      case VBadgeStatus.success:
      case VBadgeStatus.completed:
      case VBadgeStatus.paid:
        iconBgColor = colors.successBg;
        iconColor = colors.success;
        break;
      case VBadgeStatus.info:
      case VBadgeStatus.pending:
        iconBgColor = colors.infoBg;
        iconColor = colors.info;
        break;
      default:
        iconBgColor = colors.surfaceAlt;
        iconColor = colors.textSecondary;
    }

    return Semantics(
      label: semanticLabel ?? title,
      button: onTap != null,
      child: VCard(
        onTap: onTap,
        padding: const EdgeInsets.all(VSpacing.space3),
        tone: tone,
        emphasis: emphasis,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(VRadius.r12),
              ),
              alignment: Alignment.center,
              child: IconTheme(
                data: IconThemeData(
                  color: iconColor,
                  size: 18,
                ),
                child: leadingIcon,
              ),
            ),
            const SizedBox(width: VSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: VTypography.bodyDefault.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: VTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: VSpacing.space2),
            VBadge(
              label: badgeLabel,
              status: badgeStatus,
            ),
            const SizedBox(width: VSpacing.space1),
            Icon(
              Icons.chevron_right,
              color: colors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
