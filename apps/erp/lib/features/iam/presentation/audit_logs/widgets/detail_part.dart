import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../models/audit_log_ui_model.dart';

String formatAuditTimestamp(DateTime dt) {
  final ict = VDateTime.toIct(dt);
  final day = ict.day.toString().padLeft(2, '0');
  final month = ict.month.toString().padLeft(2, '0');
  final year = ict.year;
  final hour = ict.hour.toString().padLeft(2, '0');
  final minute = ict.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

String formatAuditDayHeader(DateTime dt) {
  final ict = VDateTime.toIct(dt);
  final day = ict.day.toString().padLeft(2, '0');
  final month = ict.month.toString().padLeft(2, '0');
  final year = ict.year;
  return '$day/$month/$year';
}

String formatAuditTimeOnly(DateTime dt) {
  final ict = VDateTime.toIct(dt);
  final hour = ict.hour.toString().padLeft(2, '0');
  final minute = ict.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatAuditDetailTimestamp(DateTime dt) {
  final ict = VDateTime.toIct(dt);
  final day = ict.day.toString().padLeft(2, '0');
  final month = ict.month.toString().padLeft(2, '0');
  final year = ict.year;
  final hour = ict.hour.toString().padLeft(2, '0');
  final minute = ict.minute.toString().padLeft(2, '0');
  return '$day/$month/$year · $hour:$minute';
}

String formatAuditTraceId(String value) {
  if (value.length <= 24) return value;
  return '${value.substring(0, 12)}…${value.substring(value.length - 8)}';
}

Widget auditStatusBadge(AuditLogStatus status) {
  return switch (status) {
    AuditLogStatus.success => const VBadge(
        label: 'Thành công',
        tone: VComponentTone.success,
        variant: VBadgeVariant.soft,
        isSmall: true,
      ),
    AuditLogStatus.blocked => const VBadge(
        label: 'Bị chặn',
        tone: VComponentTone.warning,
        variant: VBadgeVariant.soft,
        isSmall: true,
      ),
    AuditLogStatus.error => const VBadge(
        label: 'Lỗi',
        tone: VComponentTone.danger,
        variant: VBadgeVariant.soft,
        isSmall: true,
      ),
  };
}

/// Danh sách chỉ hiện nhãn kết quả khi khác Thành công (Q15).
Widget? auditNonSuccessBadge(AuditLogStatus status) {
  return switch (status) {
    AuditLogStatus.success => null,
    AuditLogStatus.blocked => const VBadge(
        label: 'Bị chặn',
        tone: VComponentTone.warning,
        variant: VBadgeVariant.soft,
        isSmall: true,
      ),
    AuditLogStatus.error => const VBadge(
        label: 'Lỗi',
        tone: VComponentTone.danger,
        variant: VBadgeVariant.soft,
        isSmall: true,
      ),
  };
}

String formatAuditActorSummary(AuditLogItemUiModel log) {
  if (log.actorRole.isNotEmpty && log.actorRole != '—') {
    return '${log.actorName} (${log.actorRole})';
  }
  return log.actorName;
}

class AuditIconBox extends StatelessWidget {
  const AuditIconBox({
    super.key,
    required this.icon,
    this.size = 36,
    this.iconSize = 18,
  });

  final VIcons icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceBrand,
          borderRadius: BorderRadius.circular(8),
        ),
        child: VIcon(
          icon: icon,
          size: iconSize,
          color: colors.textBrand,
        ),
      ),
    );
  }
}

/// Một phần trong thẻ chi tiết hoạt động.
class DetailPart extends StatelessWidget {
  const DetailPart({
    super.key,
    required this.title,
    this.trailing,
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.wideHeader = false,
  });

  final String title;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool wideHeader;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: VText(
                    title,
                    variant: wideHeader
                        ? VTextVariant.bodySmall
                        : VTextVariant.headingH4,
                    style: wideHeader
                        ? TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                          )
                        : TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          for (var i = 0; i < children.length; i++) ...[
            SizedBox(height: i == 0 ? 12 : 10),
            children[i],
          ],
        ],
      ),
    );
  }
}
