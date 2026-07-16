import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_presentation/presentation.dart';

/// List / loading / error / empty body for partner list page.
class PartnerListBody extends StatelessWidget {
  const PartnerListBody({
    super.key,
    required this.scrollController,
    required this.canCreate,
    required this.onRefresh,
    required this.onRetry,
    required this.onClearQuery,
    required this.onCreate,
    required this.onTapPartner,
  });

  final ScrollController scrollController;
  final bool canCreate;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onClearQuery;
  final VoidCallback onCreate;
  final ValueChanged<String> onTapPartner;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PartnerListCubit, PartnerListState>(
      builder: (context, state) {
        if (state is PartnerListInitial || (state is PartnerListLoading && state.isFirstLoad)) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PartnerListError) {
          return Center(
            child: VEmptyState(
              iconData: Icons.cloud_off_rounded,
              tone: VComponentTone.danger,
              title: 'Không tải được danh sách',
              description: 'Vui lòng kiểm tra kết nối internet\nhoặc thử lại sau.',
              actionLabel: 'Thử lại',
              onActionPressed: onRetry,
            ),
          );
        }

        final items = switch (state) {
          PartnerListLoaded(:final items) => items,
          PartnerListLoading(:final items) => items,
          _ => <PartnerListItemDto>[],
        };

        if (items.isEmpty && state is! PartnerListLoading) {
          final hasQuery = state.query != null && state.query!.isNotEmpty;
          if (hasQuery) {
            return Center(
              child: VEmptyState(
                iconData: Icons.search_rounded,
                title: 'Không tìm thấy kết quả',
                description: 'Thử kiểm tra lại từ khóa "${state.query}"\nhoặc bộ lọc.',
                actionLabel: 'Xóa từ khóa',
                onActionPressed: onClearQuery,
              ),
            );
          }
          return Center(
            child: VEmptyState(
              iconData: Icons.assignment_outlined,
              title: 'Chưa có KH & NCC',
              description: 'Thêm đối tác để bắt đầu bán hàng,\nnhập hàng và quản lý công nợ.',
              actionLabel: canCreate ? 'Thêm KH & NCC' : null,
              actionLeadingIcon: canCreate
                  ? Icon(Icons.add, size: 18, color: context.vColors.success)
                  : null,
              onActionPressed: canCreate ? onCreate : null,
            ),
          );
        }

        final hasReachedMax = state is PartnerListLoaded && state.hasReachedMax;

        return RefreshIndicator(
          onRefresh: onRefresh,
          displacement: VSpacing.md,
          child: VPagePadding(
            child: ListView.separated(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: VSpacing.md),
              itemCount: items.length + (hasReachedMax ? 0 : 1),
              separatorBuilder: (context, index) => const SizedBox(height: VSpacing.space3),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: VSpacing.space4),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final item = items[index];
                return PartnerListItemTile(
                  item: item,
                  onTap: () => onTapPartner(item.partnerId),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
