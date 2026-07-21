import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Thin wrappers domain — UI thật dùng [VBanner] từ design system.

/// D-06 SG-03 — Cảnh báo giá riêng thấp hơn giá sàn.
class PriceRuleBelowFloorBanner extends StatelessWidget {
  const PriceRuleBelowFloorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const VBanner(
      tone: VComponentTone.warning,
      title: 'Giá riêng thấp hơn giá sàn',
      message: 'Bạn vẫn có thể lưu nếu có quyền ghi đè giá sàn.',
    );
  }
}

/// D-06 SG-03 — Cảnh báo trùng giá riêng (không chặn lưu).
class PriceRuleDuplicateBanner extends StatelessWidget {
  const PriceRuleDuplicateBanner({
    super.key,
    this.onViewExisting,
  });

  final VoidCallback? onViewExisting;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VBanner(
      tone: VComponentTone.danger,
      title: 'Trùng giá riêng đang áp dụng',
      message:
          'Đã có giá riêng cho khách hàng, sản phẩm, đơn vị '
          'trong khoảng thời gian. Lưu giá riêng mới sẽ ghi đè '
          'giá riêng cũ.',
      footer: onViewExisting == null
          ? null
          : GestureDetector(
              onTap: onViewExisting,
              child: VText(
                'Xem giá riêng hiện có >',
                variant: VTextVariant.labelSmall,
                color: colors.danger,
              ),
            ),
    );
  }
}

/// Banner cần kiểm tra cho màn chi tiết (D-06 needsReview / dưới sàn).
class PriceRuleReviewBanner extends StatelessWidget {
  const PriceRuleReviewBanner({
    super.key,
    required this.issues,
  });

  final List<String> issues;

  @override
  Widget build(BuildContext context) {
    final message = issues.isEmpty
        ? null
        : issues.map((issue) => '• $issue').join('\n');
    return VBanner(
      tone: VComponentTone.warning,
      title: 'Cần kiểm tra',
      message: message,
    );
  }
}

/// Alias giữ tương thích call-site cũ (info/disabled banner).
class PriceRuleBanner extends StatelessWidget {
  const PriceRuleBanner({
    super.key,
    required this.tone,
    required this.title,
    this.message,
    this.icon,
    this.trailing,
    this.footer,
  });

  final VComponentTone tone;
  final String title;
  final String? message;
  final VIcons? icon;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return VBanner(
      tone: tone,
      title: title,
      message: message,
      icon: icon,
      trailing: trailing,
      footer: footer,
    );
  }
}
