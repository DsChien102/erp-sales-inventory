import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Empty / lỗi tải — CTA tạo nhanh tùy chọn (sheet dùng nút đáy riêng).
class SalesCustomerPickerBodyEmptyState extends StatelessWidget {
  const SalesCustomerPickerBodyEmptyState({
    super.key,
    this.onQuickCreate,
  });

  final VoidCallback? onQuickCreate;

  @override
  Widget build(BuildContext context) {
    return VEmptyState(
      key: const Key('wgt_sg04_empty'),
      child: Column(
        children: [
          const VEmptyHeader(
            children: [
              VEmptyMedia(icon: VIcons.people),
              VEmptyTitle('Chưa có khách hàng'),
              VEmptyDescription('Tiếp tục với Khách lẻ hoặc tạo nhanh.'),
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
