import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'partner_detail_page.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_presentation/presentation.dart';

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
                      child: PartnerListItem(
                        avatarText: partner.avatarText,
                        name: partner.name,
                        role: partner.role,
                        roleColor: partner.role == 'Khách hàng' ? VColors.info : (partner.role == 'Nhà cung cấp' ? VColors.warning : VColors.primary),
                        roleBgColor: partner.role == 'Khách hàng' ? VColors.infoBg : (partner.role == 'Nhà cung cấp' ? VColors.warningBg : VColors.primary100),
                        status: partner.status,
                        info: '${partner.phone.isNotEmpty ? '${partner.phone} · ' : ''}Cập nhật ${partner.updatedAt}',
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

}
