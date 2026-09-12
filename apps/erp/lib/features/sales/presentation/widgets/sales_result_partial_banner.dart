import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/sales_order/sales_transaction_result_state.dart';

class SalesResultPartialBanner extends StatelessWidget {
  const SalesResultPartialBanner({
    super.key,
    required this.issues,
  });

  final List<SalesTransactionResultIssue> issues;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) return const SizedBox.shrink();
    return const VBanner(
      title: 'Một số dữ liệu liên quan đang chờ đồng bộ. Đơn hàng vẫn đã hoàn tất.',
      status: VBannerStatus.warning,
    );
  }
}
