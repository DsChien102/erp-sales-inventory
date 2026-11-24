import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import 'sales_entry_row.dart';

/// Hàng "Phiếu bán hàng" trong hub chứng từ (SG-06 kết quả, SG-08 chi tiết đơn).
///
/// [title] / [subtitle] cho phép màn đổi chữ theo trạng thái tạo phiếu;
/// [onTap] = null khi đang tạo / in / chia sẻ.
class SalesReceiptEntryCard extends StatelessWidget {
  const SalesReceiptEntryCard({
    super.key,
    required this.onTap,
    this.title = 'Phiếu bán hàng',
    this.subtitle = 'Xem, in hoặc gửi phiếu cho khách',
  });

  final VoidCallback? onTap;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SalesEntryRow(
      icon: VIcons.receiptText,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}
