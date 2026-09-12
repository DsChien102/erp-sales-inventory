import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/sales_order_draft/sales_draft_list_cubit.dart';
import '../bloc/sales_order_draft/sales_draft_list_state.dart';
import '../models/sales_order_draft/sales_draft_list_item_vm.dart';
import '../navigation/sales_draft_pick_result.dart';
import '../navigation/sales_typed_routes.dart';
import '../widgets/sales_draft_discard_dialog.dart';
import '../widgets/sales_draft_list_body.dart';
import '../widgets/sales_draft_list_search_bar.dart';

/// SG-01 — Đơn nháp (VTabs compound + swipe xóa trên SalesDraftListCard).
class SalesDraftListPage extends StatefulWidget {
  const SalesDraftListPage({super.key});

  @override
  State<SalesDraftListPage> createState() => _SalesDraftListPageState();
}

class _SalesDraftListPageState extends State<SalesDraftListPage> {
  late final SalesDraftListCubit _cubit;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<SalesDraftListCubit>()..load();
  }

  void _openCreateOrder() {
    if (context.canPop()) {
      context.pop(const SalesDraftPickNew());
    } else {
      const SalesComposeRoute().pushReplacement(context);
    }
  }

  void _openDraft(SalesDraftListItemVm item) {
    if (context.canPop()) {
      context.pop(SalesDraftPickExisting(item.draftId));
    } else {
      SalesComposeRoute(draftId: item.draftId).pushReplacement(context);
    }
  }

  Future<void> _discardDraft(SalesDraftListItemVm item) async {
    final confirmed = await showSalesDraftDiscardDialog(context, item: item);
    if (!confirmed || !mounted) return;

    final ok = await _cubit.discardDraft(
      item.draftId,
      expectedVersion: item.version,
    );
    if (!mounted) return;

    if (ok) {
      VToast.show(
        context,
        title: 'Đã xóa đơn nháp',
        message: 'Đơn nháp của ${item.customerLabel} đã được xóa.',
        type: VToastType.success,
      );
    }
  }

  SalesDraftListBody _draftListBody(
    SalesDraftListState state, {
    required SalesDraftScopeFilter displayScope,
  }) {
    return SalesDraftListBody(
      state: state,
      displayScope: displayScope,
      onRefresh: () => _cubit.load(isRefresh: true),
      onRetry: () => _cubit.load(isRefresh: true),
      onTapDraft: _openDraft,
      onDiscardDraft: _discardDraft,
      onClearSearch: _cubit.clearSearch,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocListener<SalesDraftListCubit, SalesDraftListState>(
      listenWhen: (previous, current) =>
          previous.actionMessage != current.actionMessage && current.actionMessage != null,
      listener: (context, state) {
        VToast.show(
          context,
          title: 'Không xóa được đơn nháp',
          message: state.actionMessage ?? 'Đơn nháp đã thay đổi. Vui lòng tải lại danh sách.',
          type: VToastType.danger,
        );
      },
      child: BlocBuilder<SalesDraftListCubit, SalesDraftListState>(
        builder: (context, state) {
          return VPageScaffold(
            key: const Key('wgt_e01_u01_page'),
            title: 'Đơn nháp',
            centerTitle: false,
            showBackButton: true,
            floatingActionButton: VFloatingActionButton(
              key: const Key('btn_create_sales_draft'),
              icon: VIcons.add,
              tone: VComponentTone.success,
              backgroundColor: colors.success,
              semanticLabel: 'Tạo đơn mới',
              onTap: _openCreateOrder,
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const VGap.sm(),
                VPagePadding(
                  child: SalesDraftListSearchBar(
                    initialQuery: state.query,
                    onSearch: _cubit.searchByKeyword,
                  ),
                ),
                const VGap.sm(),
                Expanded(
                  child: VTabs(
                    key: const Key('tabs_sales_draft_scope'),
                    selectedIndex: _tabIndex,
                    onTabSelected: (index) => setState(() => _tabIndex = index),
                    tone: VComponentTone.success,
                    semanticLabel: 'Phạm vi đơn nháp',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VPagePadding(
                          child: VTabsList(
                            children: const [
                              VTabsTrigger(label: 'Đơn của tôi'),
                              VTabsTrigger(label: 'Tất cả đơn nháp'),
                            ],
                          ),
                        ),
                        VTabsContent(
                          children: [
                            _draftListBody(
                              state,
                              displayScope: SalesDraftScopeFilter.mine,
                            ),
                            _draftListBody(
                              state,
                              displayScope: SalesDraftScopeFilter.all,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
