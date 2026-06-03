import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VET45 Design System Preview',
      theme: VTheme.lightTheme,
      home: const PreviewHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PreviewHomeScreen extends StatefulWidget {
  const PreviewHomeScreen({super.key});

  @override
  State<PreviewHomeScreen> createState() => _PreviewHomeScreenState();
}

class _PreviewHomeScreenState extends State<PreviewHomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VET45 Design System Preview'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: VColors.surface,
            child: VTabs(
              tabs: const [
                'Mockup App',
                'Tokens',
                'Buttons',
                'Fields',
                'Cards & Badges',
                'New Specs',
              ],
              selectedIndex: _currentTab,
              isScrollable: true,
              onTabSelected: (index) {
                setState(() {
                  _currentTab = index;
                });
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentTab,
          children: const [
            VMockupTab(),
            TokensPreviewTab(),
            ButtonsPreviewTab(),
            FieldsPreviewTab(),
            CardsBadgesPreviewTab(),
            NewSpecsPreviewTab(),
          ],
        ),
      ),
    );
  }
}

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
    // Return a simulated mobile phone preview mockup
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Text(
              'THUỐC THÚ Y · PHASE 1',
              style: VTypography.headingH3.copyWith(
                color: VColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sales · Cashier · v0.5 · vi-VN',
              style: VTypography.caption.copyWith(color: VColors.textSecondary),
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
                  backgroundColor: VColors.background,
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
                                            color: VColors.textPrimary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '03/06/2026',
                                          style: VTypography.caption.copyWith(
                                            color: VColors.textSecondary,
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
                                            color: VColors.textPrimary,
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
                                            color: VColors.textPrimary,
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
                                            leadingIcon: const Icon(Icons.download_for_offline_outlined),
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
                                        color: VColors.textPrimary,
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
                          VBottomNavigationItem(icon: Icon(Icons.account_balance_wallet), label: 'Công nợ'),
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

/// --- TOKENS PREVIEW TAB ---
class TokensPreviewTab extends StatelessWidget {
  const TokensPreviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        _buildSectionHeader('Colors — Primary (VET45 Green)'),
        _buildColorGroup([
          _buildColorTile(
            'primary50',
            VColors.primary50,
            VColors.primary900,
          ),
          _buildColorTile(
            'primary100',
            VColors.primary100,
            VColors.primary900,
          ),
          _buildColorTile(
            'primary200',
            VColors.primary200,
            VColors.primary900,
          ),
          _buildColorTile(
            'primary300',
            VColors.primary300,
            VColors.primary900,
          ),
          _buildColorTile(
            'primary400',
            VColors.primary400,
            VColors.neutral0,
          ),
          _buildColorTile(
            'primary500',
            VColors.primary500,
            VColors.neutral0,
          ),
          _buildColorTile(
            'primary600',
            VColors.primary600,
            VColors.neutral0,
          ),
          _buildColorTile(
            'primary700',
            VColors.primary700,
            VColors.neutral0,
          ),
          _buildColorTile(
            'primary800',
            VColors.primary800,
            VColors.neutral0,
          ),
          _buildColorTile(
            'primary900',
            VColors.primary900,
            VColors.neutral0,
          ),
        ]),
        const SizedBox(height: VSpacing.space4),
        _buildSectionHeader('Colors — Neutrals'),
        _buildColorGroup([
          _buildColorTile('neutral0', VColors.neutral0, VColors.neutral900),
          _buildColorTile(
            'neutral50',
            VColors.neutral50,
            VColors.neutral900,
          ),
          _buildColorTile(
            'neutral100',
            VColors.neutral100,
            VColors.neutral900,
          ),
          _buildColorTile(
            'neutral200',
            VColors.neutral200,
            VColors.neutral900,
          ),
          _buildColorTile(
            'neutral300',
            VColors.neutral300,
            VColors.neutral900,
          ),
          _buildColorTile(
            'neutral400',
            VColors.neutral400,
            VColors.neutral900,
          ),
          _buildColorTile(
            'neutral500',
            VColors.neutral500,
            VColors.neutral0,
          ),
          _buildColorTile(
            'neutral600',
            VColors.neutral600,
            VColors.neutral0,
          ),
          _buildColorTile(
            'neutral700',
            VColors.neutral700,
            VColors.neutral0,
          ),
          _buildColorTile(
            'neutral900',
            VColors.neutral900,
            VColors.neutral0,
          ),
        ]),
        const SizedBox(height: VSpacing.space4),
        _buildSectionHeader('Colors — Semantics & Surfaces'),
        _buildColorGroup([
          _buildColorTile('success', VColors.success, VColors.neutral0),
          _buildColorTile('successBg', VColors.successBg, VColors.success),
          _buildColorTile('warning', VColors.warning, VColors.neutral0),
          _buildColorTile('warningBg', VColors.warningBg, VColors.warning),
          _buildColorTile('danger', VColors.danger, VColors.neutral0),
          _buildColorTile('dangerBg', VColors.dangerBg, VColors.danger),
          _buildColorTile('info', VColors.info, VColors.neutral0),
          _buildColorTile('infoBg', VColors.infoBg, VColors.info),
        ]),
        const SizedBox(height: VSpacing.space6),
        _buildSectionHeader('Typography'),
        VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Display D1 — 40px', style: VTypography.displayD1),
              const Divider(height: VSpacing.space4),
              Text('Heading H1 — 28px', style: VTypography.headingH1),
              const Divider(height: VSpacing.space4),
              Text('Heading H2 — 22px', style: VTypography.headingH2),
              const Divider(height: VSpacing.space4),
              Text('Heading H3 — 18px', style: VTypography.headingH3),
              const Divider(height: VSpacing.space4),
              Text('Heading H4 — 16px', style: VTypography.headingH4),
              const Divider(height: VSpacing.space4),
              Text('Body Default — 14px', style: VTypography.bodyDefault),
              const Divider(height: VSpacing.space4),
              Text('Body Small — 13px', style: VTypography.bodySmall),
              const Divider(height: VSpacing.space4),
              Text('Caption — 12px', style: VTypography.caption),
              const Divider(height: VSpacing.space4),
              Text(
                'Tabular Numeric (JetBrains Mono) — 14px',
                style: VTypography.bodyDefault,
              ),
              const SizedBox(height: VSpacing.space2),
              Text(
                '1234567890 (Standard Inter)',
                style: VTypography.bodyDefault,
              ),
              Text(
                '1234567890 (Tabular Figures)',
                style: VTypography.monoNumeric,
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space6),
        _buildSectionHeader('Shadows'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildShadowBox('e1 (Card)', VShadows.e1),
            _buildShadowBox('e2 (Hover)', VShadows.e2),
            _buildShadowBox('e3 (Popover)', VShadows.e3),
            _buildShadowBox('e4 (Modal)', VShadows.e4),
          ],
        ),
        const SizedBox(height: VSpacing.space6),
        _buildSectionHeader('Radius & Spacing Standards'),
        VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Radius Input/Button: ${VRadius.input} px',
                style: VTypography.bodyDefault,
              ),
              Text(
                'Radius Card: ${VRadius.card} px',
                style: VTypography.bodyDefault,
              ),
              Text(
                'Radius Sheet/Modal: ${VRadius.sheet} px',
                style: VTypography.bodyDefault,
              ),
              const SizedBox(height: VSpacing.space3),
              Text(
                'Mobile Screen Padding: ${VSpacing.screenMobile} px',
                style: VTypography.bodyDefault,
              ),
              Text(
                'Min Touch Target Size: ${VSpacing.minTouchTarget} px',
                style: VTypography.bodyDefault,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.space2),
      child: Text(title, style: VTypography.headingH3),
    );
  }

  Widget _buildColorGroup(List<Widget> children) {
    return VCard(
      padding: const EdgeInsets.all(VSpacing.space2),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: VSpacing.space2,
        mainAxisSpacing: VSpacing.space2,
        children: children,
      ),
    );
  }

  Widget _buildColorTile(String name, Color color, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(VRadius.r6),
        border: Border.all(color: VColors.borderDefault),
      ),
      padding: const EdgeInsets.all(VSpacing.space2),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: VTypography.bodySmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            style: VTypography.caption.copyWith(
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShadowBox(String label, List<BoxShadow> shadow) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: VColors.surface,
        borderRadius: BorderRadius.circular(VRadius.r8),
        boxShadow: shadow,
      ),
      padding: const EdgeInsets.all(VSpacing.space2),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: VTypography.caption.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// --- BUTTONS PREVIEW TAB ---
class ButtonsPreviewTab extends StatefulWidget {
  const ButtonsPreviewTab({super.key});

  @override
  State<ButtonsPreviewTab> createState() => _ButtonsPreviewTabState();
}

class _ButtonsPreviewTabState extends State<ButtonsPreviewTab> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Button State Control:', style: VTypography.headingH4),
            Row(
              children: [
                const Text('Trigger Loading:'),
                Switch(
                  value: _loading,
                  onChanged: (val) {
                    setState(() {
                      _loading = val;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const Divider(height: VSpacing.space4),
        _buildSection('Primary Buttons', [
          VButton(
            label: 'Primary Button',
            onPressed: () {},
            isLoading: _loading,
          ),
          const SizedBox(height: VSpacing.space2),
          VButton(
            label: 'With Icon',
            onPressed: () {},
            leadingIcon: const Icon(Icons.add, size: 18, color: Colors.white),
            isLoading: _loading,
          ),
          const SizedBox(height: VSpacing.space2),
          VButton(label: 'Disabled', onPressed: null, isLoading: _loading),
        ]),
        _buildSection('Secondary & Outline', [
          VButton(
            label: 'Secondary Button',
            variant: VButtonVariant.secondary,
            onPressed: () {},
            isLoading: _loading,
          ),
          const SizedBox(height: VSpacing.space2),
          VButton(
            label: 'Outline Button',
            variant: VButtonVariant.outline,
            onPressed: () {},
            isLoading: _loading,
          ),
        ]),
        _buildSection('Ghost & Danger', [
          VButton(
            label: 'Ghost Button',
            variant: VButtonVariant.ghost,
            onPressed: () {},
            isLoading: _loading,
          ),
          const SizedBox(height: VSpacing.space2),
          VButton(
            label: 'Danger Button',
            variant: VButtonVariant.danger,
            onPressed: () {},
            isLoading: _loading,
          ),
        ]),
        _buildSection('Sizes', [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VButton(
                label: 'Small',
                size: VButtonSize.small,
                onPressed: () {},
                isLoading: _loading,
              ),
              VButton(
                label: 'Medium',
                size: VButtonSize.medium,
                onPressed: () {},
                isLoading: _loading,
              ),
              VButton(
                label: 'Large',
                size: VButtonSize.large,
                onPressed: () {},
                isLoading: _loading,
              ),
            ],
          ),
        ]),
        _buildSection('Layout Options', [
          VButton(
            label: 'Full Width Button',
            fullWidth: true,
            onPressed: () {},
            isLoading: _loading,
          ),
        ]),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: VSpacing.space4,
            bottom: VSpacing.space2,
          ),
          child: Text(title, style: VTypography.headingH3),
        ),
        VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

/// --- FIELDS PREVIEW TAB ---
class FieldsPreviewTab extends StatefulWidget {
  const FieldsPreviewTab({super.key});

  @override
  State<FieldsPreviewTab> createState() => _FieldsPreviewTabState();
}

class _FieldsPreviewTabState extends State<FieldsPreviewTab> {
  final _controller1 = TextEditingController();
  final _controller2 = TextEditingController();
  final _controller3 = TextEditingController();
  bool _obscure = true;
  String? _dropdownValue = 'Reason 1';
  int _quantity = 2;

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        _buildItem(
          'Default Text Field',
          const VTextField(hintText: 'Enter text here...'),
        ),
        _buildItem(
          'With Label and Helper Text',
          VTextField(
            controller: _controller1,
            label: 'Customer Phone',
            hintText: 'e.g. 0901234567',
            helperText: 'We will send transaction details via SMS.',
          ),
        ),
        _buildItem(
          'Password Field (Toggling Visibility)',
          VTextField(
            controller: _controller2,
            label: 'Password',
            hintText: 'Enter account password',
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _obscure = !_obscure;
                });
              },
            ),
          ),
        ),
        _buildItem(
          'Error State Field',
          VTextField(
            controller: _controller3,
            label: 'Email Address',
            hintText: 'customer@gmail.com',
            errorText:
                'Email address must contain a valid domain (e.g., @gmail.com).',
          ),
        ),
        _buildItem(
          'Disabled State',
          const VTextField(
            label: 'Store Code (Read Only)',
            hintText: 'VET45_HCM_01',
            enabled: false,
            prefixIcon: Icon(Icons.store),
          ),
        ),
        _buildItem(
          'VDropdown Selector',
          VDropdown<String>(
            value: _dropdownValue,
            onChanged: (val) {
              setState(() {
                _dropdownValue = val;
              });
            },
            items: const [
              DropdownMenuItem(
                value: 'Reason 1',
                child: Text('Reason 1: Defective Product'),
              ),
              DropdownMenuItem(
                value: 'Reason 2',
                child: Text('Reason 2: Customer Return'),
              ),
              DropdownMenuItem(
                value: 'Reason 3',
                child: Text('Reason 3: Other Reason'),
              ),
            ],
          ),
        ),
        _buildItem(
          'VQuantitySelector (Min: 0, Max: 10)',
          VQuantitySelector(
            value: _quantity,
            min: 0,
            max: 10,
            onChanged: (val) {
              setState(() {
                _quantity = val;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItem(String title, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: VSpacing.space4,
            bottom: VSpacing.space2,
          ),
          child: Text(title, style: VTypography.headingH4),
        ),
        VCard(child: field),
      ],
    );
  }
}

/// --- CARDS & BADGES PREVIEW TAB ---
class CardsBadgesPreviewTab extends StatelessWidget {
  const CardsBadgesPreviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        Text('VCard Previews', style: VTypography.headingH3),
        const SizedBox(height: VSpacing.space2),
        VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resting Card (Default Outlined)',
                style: VTypography.headingH4,
              ),
              const SizedBox(height: VSpacing.space2),
              const Text(
                'This is the default card layout, outlined with borderDefault and radius of 12.',
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space3),
        VCard(
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Elevated Card (With Shadow e1)',
                style: VTypography.headingH4,
              ),
              const SizedBox(height: VSpacing.space2),
              const Text(
                'Uses VShadows.e1 for depth. Great for interactive elements in listings.',
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space3),
        VCard(
          onTap: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Card tapped!')));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tappable Card', style: VTypography.headingH4),
                  const Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
              const SizedBox(height: VSpacing.space2),
              const Text(
                'Tapping shows ink ripple splash effect properly masked inside radius.',
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space6),
        Text('VBadge Previews', style: VTypography.headingH3),
        const SizedBox(height: VSpacing.space2),
        VCard(
          child: Wrap(
            spacing: VSpacing.space2,
            runSpacing: VSpacing.space2,
            children: const [
              VBadge(label: 'Draft', status: VBadgeStatus.draft),
              VBadge(
                label: 'Pending',
                status: VBadgeStatus.pending,
                showDot: true,
              ),
              VBadge(
                label: 'Processing',
                status: VBadgeStatus.processing,
                showDot: true,
              ),
              VBadge(label: 'Completed', status: VBadgeStatus.completed),
              VBadge(
                label: 'Paid',
                status: VBadgeStatus.paid,
                showDot: true,
              ),
              VBadge(
                label: 'Partially Paid',
                status: VBadgeStatus.partiallyPaid,
              ),
              VBadge(
                label: 'Outstanding',
                status: VBadgeStatus.outstanding,
              ),
              VBadge(
                label: 'Overdue',
                status: VBadgeStatus.overdue,
                showDot: true,
              ),
              VBadge(label: 'Cancelled', status: VBadgeStatus.cancelled),
              VBadge(label: 'Locked', status: VBadgeStatus.locked),
              VBadge(label: 'Success Status', status: VBadgeStatus.success),
              VBadge(label: 'Warning Status', status: VBadgeStatus.warning),
              VBadge(
                label: 'Danger Status',
                status: VBadgeStatus.danger,
                showDot: true,
              ),
              VBadge(label: 'Info Status', status: VBadgeStatus.info),
            ],
          ),
        ),
      ],
    );
  }
}

/// --- NEW SPECS PREVIEW TAB ---
class NewSpecsPreviewTab extends StatefulWidget {
  const NewSpecsPreviewTab({super.key});

  @override
  State<NewSpecsPreviewTab> createState() => _NewSpecsPreviewTabState();
}

class _NewSpecsPreviewTabState extends State<NewSpecsPreviewTab> {
  bool _checkboxVal = false;
  bool _switchVal = false;
  int _selectedTab1 = 0;
  int _selectedTab2 = 0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        Text('Toggles & Checks', style: VTypography.headingH3),
        const SizedBox(height: VSpacing.space2),
        VCard(
          child: Column(
            children: [
              VCheckbox(
                value: _checkboxVal,
                label: 'Apply 10% VAT to all items',
                onChanged: (val) {
                  setState(() {
                    _checkboxVal = val ?? false;
                  });
                },
              ),
              const SizedBox(height: VSpacing.space2),
              VSwitch(
                value: _switchVal,
                label: 'Send digital receipt to customer',
                onChanged: (val) {
                  setState(() {
                    _switchVal = val;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space4),

        Text('Search Bars & Styled Icon Boxes', style: VTypography.headingH3),
        const SizedBox(height: VSpacing.space2),
        VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Outlined Search Bar + Circular Scan Icon (SẢN PHẨM style)
              Text('Outlined Search Bar + Circular Icon Box', style: VTypography.headingH4),
              const SizedBox(height: VSpacing.space2),
              Row(
                children: [
                  const Expanded(
                    child: VSearchBar(
                      hintText: 'Tìm sản phẩm, khách hàng...',
                      variant: VSearchBarVariant.outlined,
                    ),
                  ),
                  const SizedBox(width: VSpacing.space3),
                  VIconBox(
                    iconData: Icons.qr_code_scanner,
                    isCircular: true,
                    backgroundColor: VColors.success,
                    iconColor: Colors.white,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.space4),

              // 2. Filled Search Bar (Chọn khách hàng style)
              Text('Filled Search Bar (Modal/Sheet style)', style: VTypography.headingH4),
              const SizedBox(height: VSpacing.space2),
              const VSearchBar(
                hintText: 'Tìm theo tên, SĐT hoặc MST',
                variant: VSearchBarVariant.filled,
              ),
              const SizedBox(height: VSpacing.space4),

              // 3. Avatar Icon Containers (Khách hàng List style)
              Text('Icon Boxes / Avatars (Khách hàng style)', style: VTypography.headingH4),
              const SizedBox(height: VSpacing.space2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const VIconBox(
                        iconData: Icons.person_outline,
                        backgroundColor: VColors.neutral100,
                        iconColor: VColors.neutral600,
                      ),
                      const SizedBox(height: 4),
                      Text('Khách lẻ', style: VTypography.caption),
                    ],
                  ),
                  Column(
                    children: [
                      const VIconBox(
                        iconData: Icons.person,
                        backgroundColor: VColors.successBg,
                        iconColor: VColors.success,
                      ),
                      const SizedBox(height: 4),
                      Text('Trang trại', style: VTypography.caption),
                    ],
                  ),
                  Column(
                    children: [
                      const VIconBox(
                        iconData: Icons.business,
                        backgroundColor: VColors.successBg,
                        iconColor: VColors.success,
                      ),
                      const SizedBox(height: 4),
                      Text('Đại lý', style: VTypography.caption),
                    ],
                  ),
                  Column(
                    children: [
                      VIconBox(
                        iconData: Icons.add,
                        borderRadius: VRadius.r8,
                        backgroundColor: VColors.neutral100,
                        iconColor: VColors.success,
                        onTap: () {},
                      ),
                      const SizedBox(height: 4),
                      Text('Thêm mới', style: VTypography.caption),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space4),
        
        Text('VTabs Navigation', style: VTypography.headingH3),
        const SizedBox(height: VSpacing.space2),
        VCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              VTabs(
                tabs: const ['All', 'Pending', 'Completed', 'Cancelled'],
                selectedIndex: _selectedTab1,
                onTabSelected: (index) {
                  setState(() {
                    _selectedTab1 = index;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Text('Selected Index: $_selectedTab1', style: VTypography.bodyDefault),
              ),
              const Divider(height: 1),
              VTabs(
                tabs: const ['Overview', 'Items (12)', 'Payments', 'Activity', 'Logs', 'Settings'],
                selectedIndex: _selectedTab2,
                isScrollable: true,
                onTabSelected: (index) {
                  setState(() {
                    _selectedTab2 = index;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Text('Selected Scrollable Index: $_selectedTab2', style: VTypography.bodyDefault),
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space4),

        Text('Overlays (Dialog, Bottom Sheet, Toast)', style: VTypography.headingH3),
        const SizedBox(height: VSpacing.space2),
        VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VButton(
                label: 'Trigger Confirm Dialog',
                onPressed: () {
                  showVConfirmDialog(
                    context: context,
                    title: 'Void invoice INV-12044?',
                    message: 'This invoice will be marked as cancelled. The action is logged and cannot be undone.',
                    cancelLabel: 'Keep invoice',
                    actionLabel: 'Void',
                    isDestructive: true,
                    onAction: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invoice voided!')),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: VSpacing.space2),
              VButton(
                label: 'Trigger Bottom Sheet',
                variant: VButtonVariant.secondary,
                onPressed: () {
                  showVBottomSheet(
                    context: context,
                    title: 'Order Actions',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit_outlined),
                          title: const Text('Edit items'),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          leading: const Icon(Icons.print_outlined),
                          title: const Text('Print receipt'),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          leading: const Icon(Icons.share_outlined),
                          title: const Text('Share invoice'),
                          onTap: () => Navigator.pop(context),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.delete_outline, color: VColors.danger),
                          title: const Text('Void order', style: TextStyle(color: VColors.danger)),
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: VSpacing.space4),
              Text('Toast Notifications Examples:', style: VTypography.headingH4),
              const SizedBox(height: VSpacing.space2),
              VToast(
                title: 'Payment recorded',
                message: '1,245,000 ₫ via VietQR',
                type: VToastType.success,
                onTap: () {},
              ),
              const SizedBox(height: 4),
              VToast(
                title: 'Stock running low',
                message: 'SKU-VN-00482 · 4 units left',
                type: VToastType.warning,
                onTap: () {},
              ),
              const SizedBox(height: 4),
              VToast(
                title: 'Sync failed',
                message: 'Retrying in 30s · tap to retry now',
                type: VToastType.danger,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space4),

        Text('Data Table (Zebra Rows Disabled)', style: VTypography.headingH3),
        const SizedBox(height: VSpacing.space2),
        VCard(
          padding: EdgeInsets.zero,
          child: VTable(
            headers: const [
              VTableHeader(title: 'Invoice'),
              VTableHeader(title: 'Customer'),
              VTableHeader(title: 'Status'),
              VTableHeader(title: 'Amount', isNumeric: true),
            ],
            rows: [
              [
                Text('INV-12044', style: VTypography.monoNumeric),
                const Text('Mai Phương Retail'),
                const VBadge(label: 'Partial', status: VBadgeStatus.partiallyPaid),
                Text('2,150,000 ₫', style: VTypography.monoNumeric),
              ],
              [
                Text('INV-12043', style: VTypography.monoNumeric),
                const Text('An Nam Trading'),
                const VBadge(label: 'Paid', status: VBadgeStatus.paid),
                Text('8,420,000 ₫', style: VTypography.monoNumeric),
              ],
              [
                Text('INV-12042', style: VTypography.monoNumeric),
                const Text('Hoàng Phát O2'),
                const VBadge(label: 'Cancelled', status: VBadgeStatus.cancelled),
                Text('- 500,000 ₫', style: VTypography.monoNumeric.copyWith(color: VColors.danger)),
              ],
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space4),

        Text('Empty State Example', style: VTypography.headingH3),
        const SizedBox(height: VSpacing.space2),
        VCard(
          child: VEmptyState(
            iconEmoji: '📦',
            title: 'No purchase orders yet',
            description: 'Create your first PO to track incoming stock.',
            actionLabel: '+ New PO',
            onActionPressed: () {},
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
