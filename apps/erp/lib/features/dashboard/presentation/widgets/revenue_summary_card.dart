import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class RevenueSummaryCard extends StatelessWidget {
  const RevenueSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return VRevenueCard(
      title: 'Doanh thu hôm nay',
      amount: '8.420.000 ₫',
      subtitle: 'Từ 12 đơn · +18% so với hôm qua',
      onTap: () {},
    );
  }
}
