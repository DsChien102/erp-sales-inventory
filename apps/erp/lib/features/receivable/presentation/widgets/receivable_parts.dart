
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../logic/receivable_format.dart';

const tabularFigures = [FontFeature.tabularFigures()];

/// Kiểu chữ số tiền: đậm, số đều cột (TH-06 5.6).
TextStyle receivableMoneyStyle(
  BuildContext context, {
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w700,
  Color? color,
  double? height,
}) => VTypography.bodyDefault.copyWith(
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color ?? context.vColors.textPrimary,
  height: height,
  fontFeatures: tabularFigures,
);

/// `dueBadge` của prototype: quá hạn = icon cảnh báo + chữ đỏ; hôm nay = vàng; còn lại xám.
class ReceivableDueBadge extends StatelessWidget {
  const ReceivableDueBadge(this.label, {super.key, this.fontSize = 13, this.wrap = false});

  final DueLabel label;
  final double fontSize;

  /// `true` (dòng đơn CN-03): nhãn được xuống hàng khi hẹp, như ảnh prototype `proto-CN-03-valid-390`.
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final color = switch (label.kind) {
      DueKind.overdue => colors.danger,
      DueKind.today => colors.warning,
      _ => colors.textSecondary,
    };
    return Semantics(
      label: label.text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.kind == DueKind.overdue) ...[
            VIcon(icon: VIcons.warning, size: 16, color: color),
            const SizedBox(width: VSpacing.space1),
          ],
          Flexible(
            child: Text(
              label.text,
              softWrap: wrap,
              maxLines: wrap ? 2 : 1,
              style: VTypography.bodySmall.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReceivableInactiveBadge extends StatelessWidget {
  const ReceivableInactiveBadge({super.key});

  @override
  Widget build(BuildContext context) => const VBadge(
    label: 'Ngừng hoạt động',
    tone: VComponentTone.neutral,
    variant: VBadgeVariant.soft,
    isSmall: true,
  );
}

/// `.rc-section`: nhãn nhóm 12/700, giãn chữ 0.48.
class ReceivableSectionTitle extends StatelessWidget {
  const ReceivableSectionTitle(this.text, {super.key, this.horizontal = VSpacing.space4});

  final String text;
  final double horizontal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(horizontal, VSpacing.space5, horizontal, VSpacing.space2),
    child: Text(
      text,
      style: VTypography.caption.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.48,
        color: context.vColors.textSecondary,
      ),
    ),
  );
}

class ReceivableEmpty extends StatelessWidget {
  const ReceivableEmpty({
    super.key,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.icon = VIcons.inbox,
  });

  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VIcons icon;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: VEmptyState(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VEmptyHeader(
              children: [
                VEmptyMedia(icon: icon),
                VEmptyTitle(title),
                if (description != null) VEmptyDescription(description!),
              ],
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: VSpacing.space4),
              VButton(
                label: actionLabel!,
                variant: VButtonVariant.secondary,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// `.rc-pick`: gợi ý ở cột phải khi web chia đôi mà chưa chọn khách.
class ReceivablePickPlaceholder extends StatelessWidget {
  const ReceivablePickPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.vColors.background,
    body: Center(
      child: Text(
        'Chọn một khách để xem công nợ',
        style: VTypography.bodyDefault.copyWith(
          fontSize: 16,
          color: context.vColors.textSecondary,
        ),
      ),
    ),
  );
}
