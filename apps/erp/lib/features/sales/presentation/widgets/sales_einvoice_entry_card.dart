import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'sales_entry_row.dart';

/// Hàng "Hóa đơn điện tử" trong hub chứng từ (SG-06 kết quả, SG-08 chi tiết đơn).
///
/// Mỗi màn tự map enum trạng thái của mình sang [badgeLabel] / [badgeTone] vì
/// SG-06 dùng `IntegrationDeliveryStatus` còn SG-08 dùng `SalesEInvoiceStatus`.
class SalesEInvoiceEntryCard extends StatelessWidget {
  const SalesEInvoiceEntryCard({
    super.key,
    required this.onTap,
    required this.badgeLabel,
    this.badgeTone = VComponentTone.neutral,
    this.title = 'Hóa đơn điện tử',
    this.subtitle = 'Quản lý hóa đơn',
  });

  final VoidCallback? onTap;
  final String badgeLabel;
  final VComponentTone badgeTone;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SalesEntryRow(
      icon: VIcons.fileCheck,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      badge: VBadge(
        label: badgeLabel,
        tone: badgeTone,
      ),
    );
  }
}
