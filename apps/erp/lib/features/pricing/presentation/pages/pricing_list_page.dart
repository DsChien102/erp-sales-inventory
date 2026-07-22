import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

/// S2 — Danh sách & kiểm soát nhanh (US-01).
///
/// SG-01: Tên sản phẩm = productName (tên nội bộ).
/// SG-02: FAB + CTA dùng primary button.
class PricingListPage extends StatefulWidget {
  const PricingListPage({super.key});

  @override
  State<PricingListPage> createState() => _PricingListPageState();
}

class _PricingListPageState extends State<PricingListPage> {
  final ScrollController _scrollController = ScrollController();
  late final PriceRuleListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PriceRuleListCubit(
      pricingModule: GetIt.instance<IPricingModule>(),
      executionContext: GetIt.instance<IExecutionContext>(),
    )..fetchRules();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _cubit.fetchRules();
    }
  }

  Future<void> _openAddFlow(BuildContext context) async {
    final ruleId = await context.push<String>('/pricing/choose-method');
    if (!context.mounted) return;

    if (ruleId != null) {
      await context.push('/pricing/$ruleId');
      if (!context.mounted) return;
    }
    _cubit.refresh();
  }

  Future<void> _openDetail(BuildContext context, String ruleId) async {
    await context.push('/pricing/$ruleId');
    _cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<PriceRuleListCubit, PriceRuleListState>(
        builder: (context, state) {
          return VPageScaffold(
            key: const Key('wgt_e02_u01_fr01_01'),
            title: 'Giá riêng / Nhớ giá',
            subtitle: '${state.totalCount} giá riêng',
            body: Column(
              children: [
                PriceRuleListSearchAndFilter(cubit: _cubit),
                Expanded(
                  child: _PriceRuleListBody(
                    state: state,
                    cubit: _cubit,
                    scrollController: _scrollController,
                    onOpenAdd: () => _openAddFlow(context),
                    onOpenDetail: (ruleId) => _openDetail(context, ruleId),
                  ),
                ),
              ],
            ),
            floatingActionButton: (!state.canCreate && !state.canImport)
                ? null
                : VFloatingActionButton(
                    icon: VIcons.add,
                    onTap: () => _openAddFlow(context),
                  ),
          );
        },
      ),
    );
  }
}

class _PriceRuleListBody extends StatelessWidget {
  const _PriceRuleListBody({
    required this.state,
    required this.cubit,
    required this.scrollController,
    required this.onOpenAdd,
    required this.onOpenDetail,
  });

  final PriceRuleListState state;
  final PriceRuleListCubit cubit;
  final ScrollController scrollController;
  final VoidCallback onOpenAdd;
  final ValueChanged<String> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      PriceRuleListLoading(:final isFirstLoad) when isFirstLoad => const _PriceRuleListSkeleton(),
      PriceRuleListNoPermission() => const VEmptyState(
        icon: VIcons.lock,
        title: 'Không có quyền truy cập',
        description: 'Bạn không có quyền xem danh sách giá riêng.',
      ),
      PriceRuleListError(:final message) when state.items.isEmpty => VEmptyState(
        icon: VIcons.error,
        title: 'Không thể tải dữ liệu',
        description: message,
        actionLabel: 'Thử lại',
        onActionPressed: cubit.refresh,
      ),
      _ when state.items.isEmpty && state is PriceRuleListLoaded => VEmptyState(
        icon: VIcons.tag,
        title: 'Chưa có giá riêng nào',
        description: 'Tạo giá riêng hoặc nhập từ Excel để bắt đầu.',
        actionLabel: state.canCreate ? 'Thêm giá riêng' : null,
        onActionPressed: state.canCreate ? onOpenAdd : null,
      ),
      _ => PriceRuleListView(
        cubit: cubit,
        scrollController: scrollController,
        state: state,
        onRuleTap: onOpenDetail,
      ),
    };
  }
}

class _PriceRuleListSkeleton extends StatelessWidget {
  const _PriceRuleListSkeleton();

  @override
  Widget build(BuildContext context) {
    return VSkeletonScope(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space4,
          vertical: VSpacing.space2,
        ),
        itemCount: 6,
        separatorBuilder: (_, _) => const VGap.sm(),
        itemBuilder: (_, _) => const VCard(
          padding: EdgeInsets.all(VSpacing.space3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VSkeleton.circle(size: 40),
              VGap.horizontalMd(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VSkeleton(width: 160, height: 14),
                    VGap.sm(),
                    VSkeleton(width: 120, height: 12),
                    VGap.sm(),
                    VSkeleton(width: double.infinity, height: 14),
                    VGap.sm(),
                    VSkeleton(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
