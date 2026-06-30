import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'partner_detail_page.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/partner_list_cubit.dart';
import '../bloc/partner_list_state.dart';
import '../widgets/partner_empty_state.dart';
import '../widgets/partner_search_bar.dart';

class PartnerListPage extends StatelessWidget {
  const PartnerListPage({super.key});
  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocProvider(
      create: (_) => PartnerListCubit(),
      child: Scaffold(
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
          const PartnerSearchBar(),
          Expanded(
            child: BlocBuilder<PartnerListCubit, PartnerListState>(
              builder: (context, state) {
                if (state.status == PartnerListStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state.partners.isEmpty) {
                  return const PartnerEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  itemCount: state.partners.length,
                  separatorBuilder: (context, index) => const SizedBox(height: VSpacing.space3),
                  itemBuilder: (context, index) {
                    final partner = state.partners[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PartnerDetailPage(partner: partner)));
                      },
                      child: _buildPartnerItem(
                        context,
                        avatarText: partner.avatarText,
                        name: partner.name,
                        role: partner.role,
                        roleColor: partner.role == 'Khách hàng' ? VColors.info : (partner.role == 'Nhà cung cấp' ? VColors.warning : VColors.primary),
                        roleBgColor: partner.role == 'Khách hàng' ? VColors.infoBg : (partner.role == 'Nhà cung cấp' ? VColors.warningBg : VColors.primary100),
                        status: partner.status,
                        info: '${partner.phone.isNotEmpty ? partner.phone + ' · ' : ''}Cập nhật ${partner.updatedAt}',
                      ),
                    );
                  },
                );
              },
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
