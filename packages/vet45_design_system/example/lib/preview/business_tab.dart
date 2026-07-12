import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'preview_section.dart';

class BusinessPreviewTab extends StatelessWidget {
  const BusinessPreviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        PreviewSection(
          title: 'VCreateOrderButton',
          child: VCreateOrderButton(
            title: 'Tạo đơn hàng',
            subtitle: 'Tạo thông tin đơn hàng',
            icon: Icons.add,
            onTap: () {},
          ),
        ),
        PreviewSection(
          title: 'VRevenueCard',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Default',
                child: VRevenueCard(
                  title: 'Doanh thu hôm nay',
                  amount: '8.420.000 ₫',
                  subtitle: 'Từ 12 đơn · +18%',
                  onTap: () {},
                ),
              ),
              PreviewStateRow(
                label: 'Zero / empty-ish',
                child: VRevenueCard(
                  title: 'Doanh thu hôm nay',
                  amount: '0 ₫',
                  subtitle: 'Chưa có đơn',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VMetricCard',
          child: Row(
            children: [
              Expanded(
                child: VMetricCard(
                  icon: const Icon(Icons.receipt_long),
                  value: '12',
                  label: 'Đơn hôm nay',
                  iconColor: VColors.info,
                  iconBgColor: VColors.infoBg,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Expanded(
                child: VMetricCard(
                  icon: const Icon(Icons.inventory_2),
                  value: '0',
                  label: 'Sắp hết',
                  iconColor: VColors.danger,
                  iconBgColor: VColors.dangerBg,
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VTodoItem',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Danger badge',
                child: VTodoItem(
                  leadingIcon: const Icon(Icons.monetization_on_outlined),
                  title: 'Trang trại Minh An',
                  subtitle: 'Quá hạn 12 ngày · 1.200.000 ₫',
                  badgeLabel: 'QUÁ HẠN',
                  badgeStatus: VBadgeStatus.danger,
                  onTap: () {},
                ),
              ),
              PreviewStateRow(
                label: 'Warning badge',
                child: VTodoItem(
                  leadingIcon: const Icon(Icons.inventory_2_outlined),
                  title: 'Enrofloxacin 10%',
                  subtitle: 'Còn 4 chai',
                  badgeLabel: 'SẮP HẾT',
                  badgeStatus: VBadgeStatus.warning,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VActivityItem',
          child: VCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                VActivityItem(
                  leadingIcon: const Icon(Icons.shopping_cart_outlined),
                  title: 'Đơn mới · DH-018',
                  subtitle: 'Trang trại Minh An · 524.000 ₫',
                  badgeLabel: 'Còn nợ',
                  badgeStatus: VBadgeStatus.warning,
                  time: '09:15',
                  onTap: () {},
                ),
                const Divider(height: 1),
                VActivityItem(
                  leadingIcon: const Icon(Icons.payments_outlined),
                  title: 'Thu chuyển khoản',
                  subtitle: 'DH-017 · Đại lý Hoàng Phát',
                  badgeLabel: 'Đã thanh toán',
                  badgeStatus: VBadgeStatus.success,
                  time: '08:50',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
