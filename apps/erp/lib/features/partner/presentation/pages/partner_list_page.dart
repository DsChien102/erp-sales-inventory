import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerListPage extends StatelessWidget {
  const PartnerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Scaffold(
      backgroundColor: dynamicColors.background,
      appBar: VAppBar(
        title: 'Khách hàng & Nhà cung cấp',
        showBackButton: false,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: dynamicColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: dynamicColors.surface,
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Row(
              children: [
                Expanded(
                  child: VTextField(
                    hintText: 'Tìm tên, SĐT, email, MST',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(VRadius.input),
                      borderSide: BorderSide(color: dynamicColors.borderDefault),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(VRadius.input),
                      borderSide: BorderSide(color: dynamicColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dynamicColors.surface,
                    borderRadius: BorderRadius.circular(VRadius.input),
                    border: Border.all(color: dynamicColors.borderDefault),
                  ),
                  child: Icon(Icons.tune, color: dynamicColors.textPrimary, size: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(VSpacing.space4),
              children: [
                _buildPartnerItem(
                  context,
                  avatarText: 'MP',
                  name: 'Đại lý Chăn nuôi Minh Phát',
                  role: 'Nhà cung cấp',
                  roleColor: VColors.warning,
                  roleBgColor: VColors.warningBg,
                  status: 'Đang hoạt động',
                  info: '028 3822 5511 · Cập nhật 18/06/2026',
                ),
                const SizedBox(height: VSpacing.space3),
                _buildPartnerItem(
                  context,
                  avatarText: 'TH',
                  name: 'Trần Thị Hoa',
                  role: 'Khách hàng',
                  roleColor: VColors.info,
                  roleBgColor: VColors.infoBg,
                  status: 'Đang hoạt động',
                  info: '0987 654 321 · Cập nhật 15/06/2026',
                ),
                const SizedBox(height: VSpacing.space3),
                _buildPartnerItem(
                  context,
                  avatarText: 'ĐT',
                  name: 'Cửa hàng Đức Thành',
                  role: 'Nhà cung cấp',
                  roleColor: VColors.warning,
                  roleBgColor: VColors.warningBg,
                  status: 'Đang hoạt động',
                  info: '0903 888 123 · Cập nhật 12/06/2026',
                ),
                const SizedBox(height: VSpacing.space3),
                _buildPartnerItem(
                  context,
                  avatarText: 'VA',
                  name: 'Nguyễn Văn An',
                  role: 'Khách hàng',
                  roleColor: VColors.info,
                  roleBgColor: VColors.infoBg,
                  status: 'Đang hoạt động',
                  info: '0912 345 678 · Cập nhật 30/05/2026',
                ),
                const SizedBox(height: 80), // padding for FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/partner/create');
        },
        backgroundColor: VColors.success,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPartnerItem(
    BuildContext context, {
    required String avatarText,
    required String name,
    required String role,
    required Color roleColor,
    required Color roleBgColor,
    required String status,
    required String info,
  }) {
    final dynamicColors = context.vColors;

    return VCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: VColors.successBg,
            child: Text(
              avatarText,
              style: VTypography.bodyDefault.copyWith(
                color: VColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: VTypography.bodyDefault.copyWith(
                    fontWeight: FontWeight.w600,
                    color: dynamicColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        role,
                        style: VTypography.bodySmall.copyWith(
                          color: roleColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: VColors.successBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: VTypography.bodySmall.copyWith(
                          color: VColors.success,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  info,
                  style: VTypography.bodySmall.copyWith(
                    color: dynamicColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: dynamicColors.textMuted),
        ],
      ),
    );
  }
}
