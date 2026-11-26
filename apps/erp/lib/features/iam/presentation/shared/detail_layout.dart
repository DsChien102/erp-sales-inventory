import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Ô biểu tượng 52×52 cho đầu trang chi tiết hẹp (prototype `.t1-orgm__icon`).
class DetailIconTile extends StatelessWidget {
  const DetailIconTile(this.icon, {super.key});

  final VIcons icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return ExcludeSemantics(
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceBrand,
          borderRadius: BorderRadius.circular(VRadius.iconBox),
          border: Border.all(color: colors.borderBrand),
        ),
        child: VIcon(icon: icon, size: 24, color: colors.textBrand),
      ),
    );
  }
}

/// Avatar tròn viết tắt cho đầu trang chi tiết thành viên/lời mời
/// (prototype `.t1-orgm__avatar`).
class DetailAvatar extends StatelessWidget {
  const DetailAvatar(
    this.initials, {
    super.key,
    this.size = 52,
    this.muted = false,
  });

  final String initials;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: muted ? colors.surfaceAlt : colors.surfaceBrand,
          shape: BoxShape.circle,
          border: Border.all(
            color: muted ? colors.borderStrong : colors.borderBrand,
          ),
        ),
        child: VText(
          initials,
          variant: VTextVariant.headingH4,
          style: TextStyle(
            // Ô lớn (prototype `.t1-avatar--xl` 72) dùng chữ 24.
            fontSize: size >= 72 ? 24 : null,
            fontWeight: FontWeight.w700,
            color: muted ? colors.textSecondary : colors.textBrand,
          ),
        ),
      ),
    );
  }
}

/// Đầu trang chi tiết hẹp: [leading] + tiêu đề + phụ đề/badge tùy chọn.
class DetailHeaderNarrow extends StatelessWidget {
  const DetailHeaderNarrow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.badge,
    this.badgeInline = false,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? badge;

  /// `true`: nhãn nằm cạnh tên (`.t1-selrole__name`), không xuống dòng riêng.
  final bool badgeInline;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: VSpacing.space2,
                  runSpacing: VSpacing.space1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Semantics(
                      header: true,
                      child: VText(
                        title,
                        variant: VTextVariant.headingH2,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (badge != null && badgeInline) badge!,
                  ],
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: VSpacing.space1),
                  VText(
                    subtitle!,
                    variant: VTextVariant.bodyDefault,
                    color: colors.textSecondary,
                  ),
                ],
                if (badge != null && !badgeInline) ...[
                  const SizedBox(height: VSpacing.space1),
                  badge!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Đầu trang chi tiết web: [leading] + tiêu đề + phụ đề + [trailing] tùy chọn.
class DetailHeaderWide extends StatelessWidget {
  const DetailHeaderWide({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        leading,
        const SizedBox(width: VSpacing.space4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: VText(
                  title,
                  variant: VTextVariant.headingH2,
                  style: TextStyle(
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                VText(
                  subtitle!,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textSecondary,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: VSpacing.space3),
          trailing!,
        ],
      ],
    );
  }
}

/// Thẻ khối thông tin trên màn hình hẹp (viền `borderStrong`, đệm 16, khe 12).
class DetailSectionNarrow extends StatelessWidget {
  const DetailSectionNarrow({
    super.key,
    required this.title,
    this.trailing,
    required this.children,
  });

  final String title;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      backgroundColor: colors.surface,
      padding: const EdgeInsets.all(VSpacing.space4),
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
                    variant: VTextVariant.headingH4,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          for (final child in children) ...[
            const SizedBox(height: VSpacing.space3),
            child,
          ],
        ],
      ),
    );
  }
}

/// Khối thông tin trên màn hình web (viền `borderDefault`, đệm 20, đầu khối ≥ 40).
class DetailSectionWide extends StatelessWidget {
  const DetailSectionWide({
    super.key,
    required this.title,
    this.action,
    required this.children,
    this.gap = VSpacing.space3,
  });

  final String title;
  final Widget? action;
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: VText(
                        title,
                        variant: VTextVariant.headingH4,
                        style: TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (action != null)
                    Transform.translate(
                      offset: const Offset(12, 0),
                      child: action!,
                    ),
                ],
              ),
            ),
            for (var i = 0; i < children.length; i++) ...[
              SizedBox(height: i == 0 ? VSpacing.space3 : gap),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Dòng nhãn – giá trị dùng chung cho các màn chi tiết.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.muted = false,
    this.valueMuted = false,
  });

  final String label;
  final String value;

  /// Làm mờ nhãn (dòng của đối tượng không còn hoạt động).
  final bool muted;

  /// Giá trị rỗng kiểu "(chưa có)": `textMuted`, chữ thường w500.
  final bool valueMuted;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    // Nhãn theo bề rộng chữ (prototype `flex: 0 0 auto`), tối đa 45% để chữ
    // phóng to không đẩy giá trị ra ngoài; giá trị lấy phần còn lại.
    return MergeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.45,
              ),
              child: VText(
                label,
                variant: VTextVariant.bodyDefault,
                color: muted ? colors.textMuted : colors.textSecondary,
              ),
            ),
            const SizedBox(width: VSpacing.space4),
            Expanded(
              child: VText(
                value.isEmpty ? '—' : value,
                variant: VTextVariant.bodyDefault,
                style: TextStyle(
                  fontWeight: valueMuted ? FontWeight.w500 : FontWeight.w600,
                  color: valueMuted ? colors.textMuted : colors.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
