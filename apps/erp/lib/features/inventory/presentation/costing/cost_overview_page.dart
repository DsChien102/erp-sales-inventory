import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/logic/costing/cost_overview_cubit.dart';
import 'package:erp/features/inventory/logic/costing/cost_overview_state.dart';
import 'package:erp/features/inventory/logic/costing/costing_rules.dart';
import 'package:erp/features/inventory/presentation/costing/cost_method_sheet.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/patterns/k6_task_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

/// SCR-072: Tổng quan giá vốn và chốt kỳ.
class CostOverviewPage extends StatelessWidget {
  const CostOverviewPage({
    super.key,
    this.onOpenRun,
    this.onCreateRun,
    this.onCreateRunWithPeriod,
    this.onBack,
  });

  final ValueChanged<CostRunRow>? onOpenRun;
  final ValueChanged<CostRunKind>? onCreateRun;
  final void Function(CostRunKind kind, DateTime? period)? onCreateRunWithPeriod;
  final VoidCallback? onBack;

  CostingRepository _resolveRepo(BuildContext context) {
    try {
      return context.read<CostingRepository>();
    } catch (_) {
      return getIt<CostingRepository>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => CostOverviewCubit(_resolveRepo(ctx))..load(),
      child: _CostOverviewView(
        onOpenRun: onOpenRun,
        onCreateRun: onCreateRun,
        onCreateRunWithPeriod: onCreateRunWithPeriod,
        onBack: onBack,
      ),
    );
  }
}

class _CostOverviewView extends StatefulWidget {
  const _CostOverviewView({
    this.onOpenRun,
    this.onCreateRun,
    this.onCreateRunWithPeriod,
    this.onBack,
  });

  final ValueChanged<CostRunRow>? onOpenRun;
  final ValueChanged<CostRunKind>? onCreateRun;
  final void Function(CostRunKind kind, DateTime? period)? onCreateRunWithPeriod;
  final VoidCallback? onBack;

  @override
  State<_CostOverviewView> createState() => _CostOverviewViewState();
}

class _CostOverviewViewState extends State<_CostOverviewView> {
  bool _wasCurrent = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    if (isCurrent && !_wasCurrent) {
      context.read<CostOverviewCubit>().load();
    }
    _wasCurrent = isCurrent;
  }

  VComponentTone _toComponentTone(CostStatusTone tone) {
    return tone == CostStatusTone.success
        ? VComponentTone.success
        : VComponentTone.warning;
  }

  void _handleBack(BuildContext context) {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    context.go('/warehouse');
  }

  void _handleOpenRun(BuildContext context, CostRunRow row) {
    if (widget.onOpenRun != null) {
      widget.onOpenRun!(row);
      return;
    }
    final path = row.status == CostRunStatus.published
        ? '/warehouse/costing/runs/${row.runId}/result'
        : '/warehouse/costing/runs/${row.runId}';
    context.go(path);
  }

  void _handleCreateRun(
    BuildContext context,
    CostRunKind kind,
    DateTime? period,
  ) {
    if (widget.onCreateRunWithPeriod != null) {
      widget.onCreateRunWithPeriod!(kind, period);
      return;
    }
    if (widget.onCreateRun != null) {
      widget.onCreateRun!(kind);
      return;
    }
    final periodParam = period != null
        ? '&period=${period.year}-${period.month.toString().padLeft(2, '0')}'
        : '';
    context.go('/warehouse/costing/new?kind=${kind.wire}$periodParam');
  }

  List<K7Column<CostRunRow>> _columns(BuildContext context) {
    final colors = context.vColors;
    return [
      K7Column<CostRunRow>(
        label: 'Lần tính',
        cell: (row) => Text(
          runTitle(row.kind, row.periodMonth),
          style: VTypography.bodyDefault.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      K7Column<CostRunRow>(
        label: 'Kỳ',
        cell: (row) => Text(
          periodLabel(row.periodMonth),
          style: VTypography.monoNumeric.copyWith(color: colors.textPrimary),
        ),
      ),
      K7Column<CostRunRow>(
        label: 'Phạm vi',
        cell: (row) => Text(
          'Toàn bộ sản phẩm',
          style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
        ),
      ),
      K7Column<CostRunRow>(
        label: 'Chênh lệch sẽ ghi',
        numeric: true,
        cell: (row) => Text(
          row.valueAdjustVnd != null ? signedMoney(row.valueAdjustVnd!) : '—',
          style: VTypography.monoNumeric.copyWith(color: colors.textPrimary),
        ),
      ),
      K7Column<CostRunRow>(
        label: 'Tình trạng',
        cell: (row) {
          final meta = runStatus(row);
          return VBadge(
            label: meta.label,
            tone: _toComponentTone(meta.tone),
          );
        },
      ),
    ];
  }

  List<InventoryFooterAction> _footerActions(
    BuildContext context,
    CostOverview data,
  ) {
    final actions = <InventoryFooterAction>[];
    if (!data.hasPendingRun) {
      actions.add(
        InventoryFooterAction(
          label: 'Cập nhật giữa kỳ',
          primary: false,
          onPressed: () => _handleCreateRun(
            context,
            CostRunKind.midPeriod,
            data.openPeriod,
          ),
        ),
      );
    }
    if (data.periodToClose != null) {
      actions.add(
        InventoryFooterAction(
          label: 'Chốt kỳ ${periodLabel(data.periodToClose!)}',
          primary: true,
          onPressed: () => _handleCreateRun(
            context,
            CostRunKind.periodClose,
            data.periodToClose,
          ),
        ),
      );
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CostOverviewCubit>();
    final state = cubit.state;
    final data = state.data;
    final isWide = inventoryIsWide(context);
    final isReady = state.status == CostOverviewStatus.ready && data != null;
    final footerActions =
        isReady ? _footerActions(context, data) : const <InventoryFooterAction>[];

    return VPageScaffold(
      title: 'Giá vốn',
      subtitle: isReady ? 'Chính sách: ${methodCopy(data.method).$1}' : null,
      contentMaxWidth: isWide
          ? VPageScaffold.fullWidth
          : VPageScaffold.defaultContentMaxWidth,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Quay về Kho',
        onPressed: () => _handleBack(context),
      ),
      actions: isReady && !data.methodLocked
          ? [
              VButton(
                label: 'Đổi',
                variant: VButtonVariant.tertiary,
                onPressed: () => showCostMethodSheet(
                  context,
                  initialMethod: data.method,
                  cubit: cubit,
                ),
              ),
            ]
          : null,
      bottomBar: footerActions.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space4,
                vertical: VSpacing.space3,
              ),
              child: InventoryFooter(actions: footerActions),
            )
          : null,
      body: Builder(
        builder: (context) {
          if (state.status == CostOverviewStatus.loading) {
            return const Padding(
              padding: EdgeInsets.all(VSpacing.space4),
              child: InventoryLoading(
                blocks: [
                  InventorySkeletonBlock.row,
                  InventorySkeletonBlock.row,
                  InventorySkeletonBlock.row,
                ],
              ),
            );
          }

          if (state.status == CostOverviewStatus.denied) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: InventoryDenied(
                  what: 'xem giá vốn',
                  next: 'Chỉ chủ cửa hàng xem và công bố giá vốn.',
                  onExit: () => _handleBack(context),
                ),
              ),
            );
          }

          if (state.status == CostOverviewStatus.error || data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: InventoryEmpty(
                  title: 'Không tải được dữ liệu giá vốn',
                  description: state.message ?? 'Kiểm tra kết nối rồi thử lại.',
                  actionLabel: 'Thử lại',
                  onAction: cubit.load,
                ),
              ),
            );
          }

          final todoRuns = data.runs
              .where(
                (r) =>
                    r.status != CostRunStatus.published &&
                    r.status != CostRunStatus.superseded,
              )
              .toList(growable: false);
          final doneRuns = data.runs
              .where((r) => r.status == CostRunStatus.published)
              .toList(growable: false);
          final visibleRuns =
              state.filter == CostRunFilter.done ? doneRuns : todoRuns;
          final totalRuns = todoRuns.length + doneRuns.length;

          return RefreshIndicator(
            onRefresh: cubit.load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(VSpacing.space4),
              child: K6TaskList<CostRunRow>(
                filters: K7FilterChips(
                  items: [
                    K7Filter(
                      key: CostRunFilter.todo.name,
                      label: 'Cần làm',
                      count: todoRuns.length,
                    ),
                    K7Filter(
                      key: CostRunFilter.done.name,
                      label: 'Đã công bố',
                      count: doneRuns.length,
                    ),
                  ],
                  selected: state.filter.name,
                  onSelected: (key) => cubit.selectFilter(
                    key == CostRunFilter.done.name
                        ? CostRunFilter.done
                        : CostRunFilter.todo,
                  ),
                ),
                columns: _columns(context),
                rows: visibleRuns,
                total: totalRuns,
                title: (row) => runTitle(row.kind, row.periodMonth),
                subtitle: (row) => runStatus(row).subtitle,
                status: (row) {
                  final meta = runStatus(row);
                  return K6Status(
                    label: meta.label,
                    tone: _toComponentTone(meta.tone),
                  );
                },
                onOpen: (row) => _handleOpenRun(context, row),
                empty: const InventoryEmpty(
                  title: 'Không có công việc giá vốn',
                  description: 'Chưa có phạm vi cần cập nhật hoặc chốt kỳ.',
                ),
                filterEmpty: InventoryEmpty(
                  title: state.filter == CostRunFilter.done
                      ? 'Chưa có kỳ nào được công bố'
                      : 'Không còn việc cần làm',
                  description: 'Chọn mục khác để xem thêm.',
                  actionLabel: 'Xem tất cả',
                  onAction: () => cubit.selectFilter(
                    state.filter == CostRunFilter.done
                        ? CostRunFilter.todo
                        : CostRunFilter.done,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
