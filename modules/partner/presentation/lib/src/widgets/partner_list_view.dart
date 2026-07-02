import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_list_cubit.dart';
import '../bloc/partner_list_state.dart';
import 'partner_list_item.dart';

class PartnerListView extends StatefulWidget {
  const PartnerListView({
    super.key,
    required this.onPartnerTap,
  });

  final Future<void> Function(PartnerItemModel partner) onPartnerTap;

  @override
  State<PartnerListView> createState() => _PartnerListViewState();
}

class _PartnerListViewState extends State<PartnerListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() => _maybeLoadMore();

  void _maybeLoadMore() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    final cubit = context.read<PartnerListCubit>();
    final state = cubit.state;
    if (!state.hasMore || state.isLoadingMore) {
      return;
    }

    final position = _scrollController.position;
    final nearBottom =
        position.maxScrollExtent <= 0 ||
        position.pixels >= position.maxScrollExtent - 200;
    if (nearBottom) {
      cubit.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PartnerListCubit, PartnerListState>(
      listenWhen: (previous, current) =>
          previous.partners.length != current.partners.length ||
          previous.isLoadingMore != current.isLoadingMore,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
      },
      child: BlocBuilder<PartnerListCubit, PartnerListState>(
      builder: (context, state) {
        final itemCount = state.partners.length + (state.isLoadingMore ? 1 : 0);

        return RefreshIndicator(
          onRefresh: () => context.read<PartnerListCubit>().load(),
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(VSpacing.space4),
            itemCount: itemCount,
            separatorBuilder: (context, index) =>
                const SizedBox(height: VSpacing.space3),
            itemBuilder: (context, index) {
              if (index >= state.partners.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: VSpacing.space4),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final partner = state.partners[index];
              return GestureDetector(
                onTap: () => widget.onPartnerTap(partner),
                child: PartnerListItem(
                  avatarText: partner.avatarText,
                  name: partner.name,
                  role: partner.role,
                  roleColor: partner.role == 'Khách hàng'
                      ? VColors.info
                      : (partner.role == 'Nhà cung cấp'
                            ? VColors.warning
                            : VColors.primary),
                  roleBgColor: partner.role == 'Khách hàng'
                      ? VColors.infoBg
                      : (partner.role == 'Nhà cung cấp'
                            ? VColors.warningBg
                            : VColors.primary100),
                  status: partner.status,
                  statusColor: partner.status == 'Ngừng hoạt động'
                      ? VColors.textSecondary
                      : VColors.success,
                  statusBgColor: partner.status == 'Ngừng hoạt động'
                      ? VColors.neutral200
                      : VColors.successBg,
                  info: partner.phone.isNotEmpty ? partner.phone : '',
                ),
              );
            },
          ),
        );
      },
      ),
    );
  }
}
