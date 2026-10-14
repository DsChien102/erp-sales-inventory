import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../data/models/valuation_work_item.dart';
import '../../data/valuation_repository.dart';
import '../../logic/valuation_queue_cubit.dart';
import '../../logic/valuation_queue_state.dart';

class ValuationQueuePage extends StatelessWidget {
  const ValuationQueuePage({super.key, this.repository});

  final ValuationRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ValuationQueueCubit(
        repository: repository ?? getIt<ValuationRepository>(),
      )..loadQueue(),
      child: const _ValuationQueueView(),
    );
  }
}

class _ValuationQueueView extends StatefulWidget {
  const _ValuationQueueView();

  @override
  State<_ValuationQueueView> createState() => _ValuationQueueViewState();
}

class _ValuationQueueViewState extends State<_ValuationQueueView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: const VAppBar(
        title: 'Hàng chờ xác lập giá trị',
      ),
      body: BlocBuilder<ValuationQueueCubit, ValuationQueueState>(
        builder: (context, state) {
          final cubit = context.read<ValuationQueueCubit>();

          return Column(
            children: [
              // Search & filter section
              Container(
                padding: const EdgeInsets.all(VSpacing.space4),
                color: colors.surface,
                child: Column(
                  children: [
                    VSearchBar(
                      controller: _searchController,
                      hintText: 'Phiếu nhận hoặc nhà cung cấp',
                      onChanged: (val) => cubit.search(val),
                      onClear: () {
                        _searchController.clear();
                        cubit.search('');
                      },
                    ),
                    const VGap(VSpacing.space2),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          VChip(
                            label: 'Tất cả',
                            tone: state.filter == 'ALL'
                                ? VComponentTone.primary
                                : VComponentTone.neutral,
                            onTap: () => cubit.setFilter('ALL'),
                          ),
                          const VGap(VSpacing.space2, axis: Axis.horizontal),
                          VChip(
                            label: 'Có thể xác lập',
                            tone: state.filter == 'READY'
                                ? VComponentTone.primary
                                : VComponentTone.neutral,
                            onTap: () => cubit.setFilter('READY'),
                          ),
                          const VGap(VSpacing.space2, axis: Axis.horizontal),
                          VChip(
                            label: 'Cần xử lý',
                            tone: state.filter == 'ISSUE'
                                ? VComponentTone.primary
                                : VComponentTone.neutral,
                            onTap: () => cubit.setFilter('ISSUE'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const VDivider(),

              // Content
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state.isLoading) {
                      return const Center(child: VLoading());
                    }

                    if (state.items.isEmpty) {
                      return const Center(
                        child: VEmptyState(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VEmptyHeader(
                                children: [
                                  VEmptyMedia(icon: VIcons.inventory),
                                  VEmptyTitle('Không có công việc phù hợp'),
                                  VEmptyDescription(
                                    'Đổi từ khóa hoặc bộ lọc để xem công việc khác.',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: VSpacing.space2,
                      ),
                      itemCount: state.items.length,
                      separatorBuilder: (_, _) => const VDivider(),
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return _ValuationWorkItemTile(
                          item: item,
                          onTap: () {
                            context.push(
                              '/warehouse/valuation/receipt/${item.id}',
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ValuationWorkItemTile extends StatelessWidget {
  const _ValuationWorkItemTile({
    required this.item,
    required this.onTap,
  });

  final ValuationWorkItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space4,
          vertical: VSpacing.space3,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.receiptNumber,
                    style: VTypography.bodyDefault.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const VGap(VSpacing.space1),
                  Text(
                    '${item.supplierName} · ${item.entryType.label} · ${item.pendingLinesCount} dòng chờ',
                    style: VTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (item.status == ValuationWorkItemStatus.conflict)
              const VBadge(
                label: 'Cần đối chiếu',
                tone: VComponentTone.warning,
              )
            else if (item.status == ValuationWorkItemStatus.missing)
              const VBadge(
                label: 'Cần căn cứ',
                tone: VComponentTone.neutral,
              ),
            const VGap(VSpacing.space2, axis: Axis.horizontal),
            const VIcon(
              icon: VIcons.chevronRight,
              iconSize: VIconSize.sm,
              iconColor: VIconColor.muted,
            ),
          ],
        ),
      ),
    );
  }
}
