import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

/// Badge trạng thái giá riêng — dùng [VBadge] Polaris.
class PriceRuleStatusBadge extends StatelessWidget {
  const PriceRuleStatusBadge({super.key, required this.status});

  final CustomerPriceRuleDerivedStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, badgeStatus) = switch (status) {
      CustomerPriceRuleDerivedStatus.applying => (
        'Đang áp dụng',
        VBadgeStatus.success,
      ),
      CustomerPriceRuleDerivedStatus.notYetEffective => (
        'Chưa hiệu lực',
        VBadgeStatus.info,
      ),
      CustomerPriceRuleDerivedStatus.disabled => (
        'Đã tắt',
        VBadgeStatus.cancelled,
      ),
      CustomerPriceRuleDerivedStatus.expired => (
        'Hết hiệu lực',
        VBadgeStatus.draft,
      ),
      CustomerPriceRuleDerivedStatus.needsReview => (
        'Cần kiểm tra',
        VBadgeStatus.warning,
      ),
    };

    return VBadge(
      label: label,
      status: badgeStatus,
      isSmall: true,
    );
  }
}
