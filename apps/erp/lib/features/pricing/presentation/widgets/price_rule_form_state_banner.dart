import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// D-09 SG-03 — Dữ liệu đã thay đổi bởi người khác.
class PriceRuleStateChangedBanner extends StatelessWidget {
  const PriceRuleStateChangedBanner({
    super.key,
    required this.onReload,
  });

  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return VBanner(
      tone: VComponentTone.warning,
      title: 'Dữ liệu đã thay đổi',
      description:
          'Giá riêng này vừa được cập nhật bởi người khác. '
          'Tải lại để xem phiên bản mới nhất.',
      footer: Align(
        alignment: Alignment.centerLeft,
        child: VButton(
          label: 'Tải lại',
          variant: VButtonVariant.secondary,
          size: VButtonSize.small,
          onPressed: onReload,
        ),
      ),
    );
  }
}
