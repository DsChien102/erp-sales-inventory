import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Placeholder — lịch sử giao dịch thuộc Epic-03, backend chưa có.
class PartnerTransactionHistoryTab extends StatelessWidget {
  const PartnerTransactionHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const VEmptyState(
      iconData: Icons.receipt_long_outlined,
      title: 'Lịch sử giao dịch',
      description:
          'Tính năng này sẽ khả dụng khi Epic-03 (lịch sử giao dịch) được triển khai.',
    );
  }
}
