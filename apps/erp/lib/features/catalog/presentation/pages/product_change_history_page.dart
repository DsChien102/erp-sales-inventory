import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/product_repository.dart';
import '../../logic/product_change_history_cubit.dart';
import '../../logic/product_change_history_state.dart';
import '../widgets/product_change_history_item.dart';

class ProductChangeHistoryPage extends StatelessWidget {
  const ProductChangeHistoryPage({
    super.key,
    required this.productId,
    required this.productName,
  });

  final String productId;
  final String productName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductChangeHistoryCubit(
        productRepository: GetIt.instance<ProductRepository>(),
      )..loadHistory(productId),
      child: _ProductChangeHistoryView(
        productId: productId,
        productName: productName,
      ),
    );
  }
}

class _ProductChangeHistoryView extends StatefulWidget {
  const _ProductChangeHistoryView({
    required this.productId,
    required this.productName,
  });

  final String productId;
  final String productName;

  @override
  State<_ProductChangeHistoryView> createState() => _ProductChangeHistoryViewState();
}

class _ProductChangeHistoryViewState extends State<_ProductChangeHistoryView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ProductChangeHistoryCubit>().loadHistory(widget.productId);
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return VPageScaffold(
      title: 'Lịch sử thay đổi',
      subtitle: widget.productName,
      leading: IconButton(
        icon: VIcon(icon: VIcons.arrowBack, color: dynamicColors.textPrimary),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/products/items');
          }
        },
      ),
      body: BlocBuilder<ProductChangeHistoryCubit, ProductChangeHistoryState>(
        builder: (context, state) {
          if (state.status == ProductChangeHistoryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ProductChangeHistoryStatus.failure && state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VIcon(icon: VIcons.error, size: 48, color: dynamicColors.danger),
                  const VGap.md(),
                  VText(
                    state.errorMessage ?? 'Đã xảy ra lỗi',
                    variant: VTextVariant.bodyDefault,
                    color: dynamicColors.textSecondary,
                  ),
                  const SizedBox(height: VSpacing.space4),
                  VButton(
                    onPressed: () =>
                        context.read<ProductChangeHistoryCubit>().refresh(widget.productId),
                    label: 'Thử lại',
                    variant: VButtonVariant.secondary,
                  ),
                ],
              ),
            );
          }

          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VIcon(icon: VIcons.history, size: 48, color: dynamicColors.textMuted),
                  const VGap.md(),
                  VText(
                    'Chưa có lịch sử thay đổi nào',
                    variant: VTextVariant.bodyDefault,
                    color: dynamicColors.textSecondary,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProductChangeHistoryCubit>().refresh(widget.productId);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(VSpacing.space4),
              controller: _scrollController,
              itemCount: state.hasReachedMax ? state.items.length : state.items.length + 1,
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(VSpacing.space4),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final entry = state.items[index];
                return ProductChangeHistoryItem(entry: entry);
              },
            ),
          );
        },
      ),
    );
  }
}
