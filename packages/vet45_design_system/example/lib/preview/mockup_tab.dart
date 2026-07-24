import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// --- MOCKUP APP TAB ---
class VMockupTab extends StatefulWidget {
  const VMockupTab({super.key});

  @override
  State<VMockupTab> createState() => _AppMockupTabState();
}

class _AppMockupTabState extends State<VMockupTab> {
  int _bottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    // Return a simulated mobile phone preview mockup
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Text(
              'THUỐC THÚ Y · PHASE 1',
              style: VTypography.headingH3.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sales · Cashier · v0.5 · vi-VN',
              style: VTypography.caption.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            // Simulated Device Container
            Container(
              width: 375,
              height: 760,
              decoration: BoxDecoration(
                color: VColors.neutral900,
                borderRadius: BorderRadius.circular(36),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
                border: Border.all(
                  color: VColors.neutral300,
                  width: 8,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Scaffold(
                  backgroundColor: colors.background,
                  body: Column(
                    children: [
                      // Simulated System Status Bar
                      Container(
                        height: 24,
                        color: VColors.neutral900,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '09:42',
                              style: VTypography.caption.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: VTypography.monoFontFamily,
                              ),
                            ),
                            Text(
                              'VET45',
                              style: VTypography.caption.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '100%',
                              style: VTypography.caption.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: VTypography.monoFontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Scrollable content representing the dashboard pages
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Sticky top bar / Header
                              VHomeHeader(
                                userName: 'Lan',
                                branchName: 'Thú y Minh Phát · CN Biên Hoà',
                                hasNotification: true,
                                onBranchTap: () {},
                                onNotificationTap: () {},
                                searchBar: VSearchBar(
                                  hintText: 'Tìm đơn hàng, sản phẩm, khách hàng…',
                                  onTap: () {},
                                ),
                              ),
                              const SizedBox(height: VSpacing.space3),

                              // Quick Order Action
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
                                child: VCreateOrderButton(
                                  title: 'Tạo đơn hàng',
                                  subtitle: 'Tạo thông tin đơn hàng',
                                  icon: Icons.add,
                                  onTap: () {},
                                ),
                              ),
                              const SizedBox(height: VSpacing.space4),

                              // Today Overview Section
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Tổng quan hôm nay',
                                          style: VTypography.headingH4.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colors.textPrimary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '03/06/2026',
                                          style: VTypography.caption.copyWith(
                                            color: colors.textSecondary,
                                            fontFamily: VTypography.monoFontFamily,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: VSpacing.space2),
                                    VRevenueCard(
                                      title: 'Doanh thu hôm nay',
                                      amount: '8.420.000 ₫',
                                      subtitle: 'Từ 12 đơn · +18% so với hôm qua',
                                      onTap: () {},
                                    ),
                                    const SizedBox(height: VSpacing.space2),
                                    Row(
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
                                            icon: const Icon(Icons.account_balance_wallet),
                                            value: '3.4tr',
                                            label: 'Phải thu',
                                            iconColor: VColors.warning,
                                            iconBgColor: VColors.warningBg,
                                            onTap: () {},
                                          ),
                                        ),
                                        const SizedBox(width: VSpacing.space2),
                                        Expanded(
                                          child: VMetricCard(
                                            icon: const Icon(Icons.inventory_2),
                                            value: '2',
                                            label: 'Sắp hết',
                                            iconColor: VColors.danger,
                                            iconBgColor: VColors.dangerBg,
                                            onTap: () {},
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: VSpacing.space4),

                              // Actions Required Section
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Việc cần xử lý',
                                          style: VTypography.headingH4.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colors.textPrimary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {},
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Xem tất cả',
                                                style: VTypography.caption.copyWith(
                                                  color: VColors.primary500,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.chevron_right,
                                                color: VColors.primary500,
                                                size: 14,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: VSpacing.space2),
                                    VTodoItem(
                                      leadingIcon: const Icon(Icons.monetization_on_outlined),
                                      title: 'Trang trại Minh An',
                                      subtitle: 'Quá hạn 12 ngày · 1.200.000 ₫',
                                      badgeLabel: 'QUÁ HẠN',
                                      badgeStatus: VBadgeStatus.danger,
                                      onTap: () {},
                                    ),
                                    const SizedBox(height: VSpacing.space2),
                                    VTodoItem(
                                      leadingIcon: const Icon(Icons.inventory_2_outlined),
                                      title: 'Enrofloxacin 10%',
                                      subtitle: 'Còn 4 chai · SKU ENR-10-100',
                                      badgeLabel: 'SẮP HẾT',
                                      badgeStatus: VBadgeStatus.warning,
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: VSpacing.space4),

                              // Recent Activities Section
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Hoạt động gần đây',
                                          style: VTypography.headingH4.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colors.textPrimary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {},
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Xem tất cả',
                                                style: VTypography.caption.copyWith(
                                                  color: VColors.primary500,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.chevron_right,
                                                color: VColors.primary500,
                                                size: 14,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: VSpacing.space2),
                                    VCard(
                                      padding: EdgeInsets.zero,
                                      child: Column(
                                        children: [
                                          VActivityItem(
                                            leadingIcon: const Icon(Icons.shopping_cart_outlined),
                                            title: 'Đơn mới · DH-20260603-018',
                                            subtitle: 'Trang trại Minh An · 524.000 ₫',
                                            badgeLabel: 'Còn nợ',
                                            badgeStatus: VBadgeStatus.warning,
                                            time: '09:15',
                                            onTap: () {},
                                          ),
                                          const Divider(height: 1, indent: 16, endIndent: 16),
                                          VActivityItem(
                                            leadingIcon: const Icon(Icons.payments_outlined),
                                            title: 'Thu chuyển khoản',
                                            subtitle: 'DH-20260603-017 · Đại lý Hoàng Phát',
                                            badgeLabel: 'Đã thanh toán',
                                            badgeStatus: VBadgeStatus.success,
                                            time: '08:50',
                                            onTap: () {},
                                          ),
                                          const Divider(height: 1, indent: 16, endIndent: 16),
                                          VActivityItem(
                                            leadingIcon: const Icon(
                                              Icons.download_for_offline_outlined,
                                            ),
                                            title: 'Nhập kho · PN-20260603-005',
                                            subtitle: 'Amoxicillin · +50 gói',
                                            badgeLabel: 'Đã hoàn tất',
                                            badgeStatus: VBadgeStatus.success,
                                            time: '08:20',
                                            onTap: () {},
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: VSpacing.space4),

                              // Quick Navigation Section
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lối tắt nghiệp vụ',
                                      style: VTypography.headingH4.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: VSpacing.space2),
                                    GridView.count(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      crossAxisCount: 4,
                                      crossAxisSpacing: VSpacing.space2,
                                      mainAxisSpacing: VSpacing.space2,
                                      childAspectRatio: 1.1,
                                      children: [
                                        VQuickActionButton(
                                          icon: const Icon(Icons.receipt_long),
                                          label: 'Đơn hàng',
                                          onTap: () {},
                                        ),
                                        VQuickActionButton(
                                          icon: const Icon(Icons.widgets),
                                          label: 'Sản phẩm',
                                          onTap: () {},
                                        ),
                                        VQuickActionButton(
                                          icon: const Icon(Icons.people),
                                          label: 'Khách hàng',
                                          onTap: () {},
                                        ),
                                        VQuickActionButton(
                                          icon: const Icon(Icons.account_balance_wallet),
                                          label: 'Công nợ',
                                          onTap: () {},
                                        ),
                                        VQuickActionButton(
                                          icon: const Icon(Icons.edit_note),
                                          label: 'Đơn nháp (3)',
                                          onTap: () {},
                                        ),
                                        VQuickActionButton(
                                          icon: const Icon(Icons.description),
                                          label: 'Hoá đơn',
                                          onTap: () {},
                                        ),
                                        VQuickActionButton(
                                          icon: const Icon(Icons.bar_chart),
                                          label: 'Báo cáo',
                                          onTap: () {},
                                        ),
                                        VQuickActionButton(
                                          icon: const Icon(Icons.settings),
                                          label: 'Thiết lập',
                                          onTap: () {},
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                      // Simulated Device Bottom Navigation Bar
                      VBottomNavigationBar(
                        currentIndex: _bottomNavIndex,
                        items: const [
                          VBottomNavigationItem(icon: Icon(Icons.home), label: 'Trang chủ'),
                          VBottomNavigationItem(icon: Icon(Icons.receipt_long), label: 'Đơn hàng'),
                          VBottomNavigationItem(icon: Icon(Icons.widgets), label: 'Sản phẩm'),
                          VBottomNavigationItem(
                            icon: Icon(Icons.account_balance_wallet),
                            label: 'Công nợ',
                          ),
                          VBottomNavigationItem(icon: Icon(Icons.more_horiz), label: 'Thêm'),
                        ],
                        onTap: (index) {
                          setState(() {
                            _bottomNavIndex = index;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
