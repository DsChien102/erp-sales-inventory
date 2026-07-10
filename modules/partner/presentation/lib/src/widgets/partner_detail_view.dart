import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';

import '../bloc/partner_detail_cubit.dart';
import '../bloc/partner_detail_state.dart';
import 'partner_detail_overview_tab.dart';
import 'partner_detail_summary_card.dart';

class PartnerDetailView extends StatelessWidget {
  const PartnerDetailView({super.key});

  static const _tabs = ['Tổng quan', 'Lịch sử', 'Tài liệu'];

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return BlocBuilder<PartnerDetailCubit, PartnerDetailState>(
      builder: (context, state) {
        return switch (state) {
          PartnerDetailInitial() || PartnerDetailLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          PartnerDetailError(:final message) => Center(child: Text('Lỗi: $message')),
          PartnerDetailLoaded(:final detail, :final selectedTabIndex) => ColoredBox(
            color: colors.background,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    VSpacing.space4,
                    VSpacing.space2,
                    VSpacing.space4,
                    VSpacing.space2,
                  ),
                  child: PartnerDetailSummaryCard(detail: detail),
                ),
                Material(
                  color: colors.surface,
                  child: VTabs(
                    tabs: _tabs,
                    selectedIndex: selectedTabIndex,
                    onTabSelected: context.read<PartnerDetailCubit>().selectTab,
                  ),
                ),
                Expanded(child: _tabBody(selectedTabIndex, detail)),
              ],
            ),
          ),
        };
      },
    );
  }

  Widget _tabBody(int index, PartnerDetailDto detail) {
    return switch (index) {
      0 => PartnerDetailOverviewTab(detail: detail),
      _ => const Center(child: Text('Nội dung sẽ có ở bản cập nhật tiếp theo.')),
    };
  }
}
