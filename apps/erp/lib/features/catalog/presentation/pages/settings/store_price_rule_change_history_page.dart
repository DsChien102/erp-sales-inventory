import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

import '../../widgets/store_price_rule_change_history_entry_card.dart';

class StorePriceRuleChangeHistoryPage extends StatelessWidget {
  const StorePriceRuleChangeHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StorePriceRuleChangeHistoryCubit(
        moduleMediator: GetIt.instance<ICatalogModule>(),
        executionContext: GetIt.instance<IExecutionContext>(),
      )..load(),
      child: const _ChangeHistoryBody(),
    );
  }
}

class _ChangeHistoryBody extends StatelessWidget {
  const _ChangeHistoryBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: const VAppBar(
        title: 'Lịch sử thay đổi',
        showBackButton: true,
      ),
      body: BlocBuilder<StorePriceRuleChangeHistoryCubit,
          StorePriceRuleChangeHistoryState>(
        builder: (context, state) {
          if (state is StorePriceRuleChangeHistoryLoading ||
              state is StorePriceRuleChangeHistoryInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StorePriceRuleChangeHistoryError) {
            return Center(
              child: Text(
                state.message,
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            );
          }

          if (state is! StorePriceRuleChangeHistoryLoaded) {
            return const SizedBox.shrink();
          }

          return _buildContent(context, state);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    StorePriceRuleChangeHistoryLoaded state,
  ) {
    final colors = context.vColors;

    if (state.items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        children: [
          _infoCard(context),
          const SizedBox(height: VSpacing.space4),
          _emptyState(context),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200 &&
            state.canLoadMore &&
            !state.isLoadingMore) {
          context.read<StorePriceRuleChangeHistoryCubit>().loadMore();
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        children: [
          _infoCard(context),
          const SizedBox(height: VSpacing.space4),
          ...state.items.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.space3),
              child: StorePriceRuleChangeHistoryEntryCard(entry: entry),
            ),
          ),
          if (state.isLoadingMore)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context) {
    final colors = context.vColors;
    return Container(
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: colors.surfaceBrand,
        borderRadius: BorderRadius.circular(VRadius.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.primary),
          const SizedBox(width: VSpacing.space2),
          Expanded(
            child: Text(
              'Lịch sử chỉ ghi nhận các thay đổi khung giá cửa hàng.',
              style: VTypography.bodySmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final colors = context.vColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: VSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: colors.textMuted,
            ),
            const SizedBox(height: VSpacing.space3),
            Text(
              'Chưa có lịch sử thay đổi',
              style: VTypography.bodyDefault.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
