import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// No-result — CTA tạo nhanh tùy chọn (sheet dùng nút đáy riêng).
class SalesCustomerPickerBodyNoResultState extends StatelessWidget {
  const SalesCustomerPickerBodyNoResultState({
    super.key,
    required this.query,
    this.onQuickCreate,
  });

  final VoidCallback? onQuickCreate;
  final String query;

  @override
  Widget build(BuildContext context) {
    return VEmptyState(
      key: const Key('wgt_sg04_no_result'),
      child: Column(
        children: [
          VEmptyHeader(
            children: [
              const VEmptyMedia(icon: VIcons.search),
              const VEmptyTitle('Không tìm thấy khách hàng'),
              VEmptyDescription('Không có kết quả cho “$query”.'),
            ],
          ),
          if (onQuickCreate != null) ...[
            const VGap.sm(),
            VEmptyContent(
              child: VButton(
                label: 'Tạo nhanh khách hàng',
                variant: VButtonVariant.tertiary,
                onPressed: onQuickCreate,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
