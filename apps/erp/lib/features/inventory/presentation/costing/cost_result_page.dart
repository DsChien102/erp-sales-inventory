import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/logic/costing/cost_run_cubit.dart';
import 'package:erp/features/inventory/logic/costing/cost_run_state.dart';
import 'package:erp/features/inventory/logic/costing/costing_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/patterns/k4_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

/// SCR-077: Kết quả công bố giá vốn.
class CostResultPage extends StatelessWidget {
  const CostResultPage({
    super.key,
    required this.runId,
    this.onToList,
    this.onBack,
  });

  final String runId;
  final VoidCallback? onToList;
  final VoidCallback? onBack;

  CostingRepository _resolveRepo(BuildContext context) {
    try {
      return context.read<CostingRepository>();
    } catch (_) {
      return getIt<CostingRepository>();
    }
  }

  void _goToList(BuildContext context) {
    if (onToList != null) {
      onToList!();
      return;
    }
    context.go('/warehouse/costing');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => CostRunCubit(_resolveRepo(ctx))..load(runId),
      child: BlocBuilder<CostRunCubit, CostRunState>(
        builder: (context, state) {
          if (state.phase == CostRunPhase.calculating) {
            return const VPageScaffold(
              title: 'Kết quả công bố giá vốn',
              showBackButton: false,
              body: Padding(
                padding: EdgeInsets.all(VSpacing.space4),
                child: InventoryLoading(
                  blocks: [
                    InventorySkeletonBlock.heading,
                    InventorySkeletonBlock.card,
                    InventorySkeletonBlock.row,
                  ],
                ),
              ),
            );
          }

          if (state.phase == CostRunPhase.denied) {
            return VPageScaffold(
              title: 'Kết quả công bố giá vốn',
              showBackButton: false,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: InventoryDenied(
                    what: 'xem kết quả công bố giá vốn',
                    next: 'Chỉ chủ cửa hàng xem kết quả công bố giá vốn.',
                    onExit: onBack ?? () => _goToList(context),
                  ),
                ),
              ),
            );
          }

          final run = state.run;
          if (state.phase == CostRunPhase.error || run == null) {
            return VPageScaffold(
              title: 'Kết quả công bố giá vốn',
              showBackButton: false,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: InventoryEmpty(
                    title: 'Không tải được kết quả công bố giá vốn',
                    description:
                        state.message ?? 'Kiểm tra kết nối rồi thử lại.',
                    actionLabel: 'Thử lại',
                    onAction: () => context.read<CostRunCubit>().load(runId),
                  ),
                ),
              ),
            );
          }

          final toList = InventoryFooterAction(
            label: 'Về giá vốn',
            primary: true,
            onPressed: () => _goToList(context),
          );

          if (run.status != CostRunStatus.published) {
            return K4ResultPage(
              screenTitle: 'Kết quả công bố giá vốn',
              kind: K4Kind.warning,
              title: 'Chưa công bố giá vốn',
              description:
                  'Không có điều chỉnh hoặc phiên bản giá vốn mới.',
              facts: [
                VKeyValueRow(
                  label: 'Kỳ ghi nhận',
                  value: periodLabel(run.periodMonth),
                  mono: true,
                ),
              ],
              next: [toList],
            );
          }

          return K4ResultPage(
            screenTitle: 'Kết quả công bố giá vốn',
            title: 'Đã công bố giá vốn ${periodLabel(run.periodMonth)}',
            description:
                'Phần chênh lệch đã được ghi và giá vốn chính thức mới đã có hiệu lực.',
            facts: [
              VKeyValueRow(
                label: 'Kỳ ghi nhận',
                value: periodLabel(run.periodMonth),
                mono: true,
              ),
              VKeyValueRow(
                label: 'Phương pháp',
                value: methodCopy(run.method).$1,
              ),
              VKeyValueRow(
                label: 'Sản phẩm có giá vốn mới',
                value: run.changedCount.toString(),
                mono: true,
              ),
              VKeyValueRow(
                label: 'Điều chỉnh giá vốn xuất',
                value: signedMoney(run.totals.cogsAdjust),
                mono: true,
              ),
              VKeyValueRow(
                label: 'Điều chỉnh giá trị tồn',
                value: signedMoney(run.totals.valueAdjust),
                mono: true,
              ),
              VKeyValueRow(
                label: 'Công bố lúc',
                value: formatDateTimeDdMmYyyyHm(
                  run.publishedAt ?? run.createdAt,
                ),
                mono: true,
              ),
            ],
            next: [toList],
          );
        },
      ),
    );
  }
}

