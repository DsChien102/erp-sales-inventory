import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/logic/costing/cost_run_cubit.dart';
import 'package:erp/features/inventory/logic/costing/cost_run_state.dart';
import 'package:erp/features/inventory/logic/costing/costing_rules.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/patterns/k4_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

/// SCR-077: Kết quả công bố giá vốn.
class CostResultPage extends StatelessWidget {
  const CostResultPage({
    super.key,
    required this.runId,
    this.onToList,
    this.onBack,
    this.onOpenReport,
    this.clock,
  });

  final String runId;
  final VoidCallback? onToList;
  final VoidCallback? onBack;

  /// Nhận đường dẫn báo cáo (tồn / lãi gộp) của kỳ vừa công bố. Mặc định `context.push`.
  final ValueChanged<String>? onOpenReport;
  final DateTime Function()? clock;

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

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    _goToList(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => CostRunCubit(_resolveRepo(ctx))..load(runId),
      child: BlocBuilder<CostRunCubit, CostRunState>(
        builder: (context, state) {
          if (state.phase == CostRunPhase.calculating) {
            return VPageScaffold(
              title: 'Kết quả công bố giá vốn',
              showBackButton: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Quay lại',
                onPressed: () => _handleBack(context),
              ),
              body: const Padding(
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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Quay lại',
                onPressed: () => _handleBack(context),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: InventoryDenied(
                    what: 'xem kết quả công bố giá vốn',
                    next: 'Chỉ chủ cửa hàng xem kết quả công bố giá vốn.',
                    onExit: () => _handleBack(context),
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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Quay lại',
                onPressed: () => _handleBack(context),
              ),
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
              onBack: () => _handleBack(context),
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

          final period = ReportPeriod.ofMonth(
            run.periodMonth,
            (clock ?? DateTime.now)(),
          );
          final query = Uri(queryParameters: period.toQuery()).query;
          void openReport(String path) {
            final target = '$path?$query';
            if (onOpenReport != null) {
              onOpenReport!(target);
              return;
            }
            context.push(target);
          }

          return K4ResultPage(
            screenTitle: 'Kết quả công bố giá vốn',
            onBack: () => _handleBack(context),
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
            next: [
              InventoryFooterAction(
                label: toList.label,
                onPressed: toList.onPressed,
              ),
              InventoryFooterAction(
                label: 'Xem báo cáo lãi gộp',
                onPressed: () => openReport('/warehouse/reports/gross-profit'),
              ),
              InventoryFooterAction(
                label: 'Xem báo cáo tồn',
                primary: true,
                onPressed: () => openReport('/warehouse/reports/stock'),
              ),
            ],
          );
        },
      ),
    );
  }
}

