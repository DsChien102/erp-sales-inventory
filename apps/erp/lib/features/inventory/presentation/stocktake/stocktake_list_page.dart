import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_list_cubit.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_list_state.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/patterns/k6_task_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

String _formatOpenedAt(DateTime dt) {
  final local = dt.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// SCR-042: Danh sách phiên kiểm kê kho.
class StocktakeListPage extends StatelessWidget {
  const StocktakeListPage({
    super.key,
    required this.onOpen,
    required this.onCreate,
    this.onBack,
  });

  final ValueChanged<StocktakeListRow> onOpen;
  final VoidCallback onCreate;
  final VoidCallback? onBack;

  StocktakeRepository _resolveRepo(BuildContext context) {
    try {
      return context.read<StocktakeRepository>();
    } catch (_) {
      return getIt<StocktakeRepository>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StocktakeListCubit(
        repository: _resolveRepo(context),
      )..load(),
      child: _StocktakeListView(
        onOpen: onOpen,
        onCreate: onCreate,
        onBack: onBack,
      ),
    );
  }
}

class _StocktakeListView extends StatefulWidget {
  const _StocktakeListView({
    required this.onOpen,
    required this.onCreate,
    this.onBack,
  });

  final ValueChanged<StocktakeListRow> onOpen;
  final VoidCallback onCreate;
  final VoidCallback? onBack;

  @override
  State<_StocktakeListView> createState() => _StocktakeListViewState();
}

class _StocktakeListViewState extends State<_StocktakeListView> {
  bool? _wasCurrent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCurrent = ModalRoute.of(context)?.isCurrent;
    if (_wasCurrent == false && isCurrent == true) {
      Future.microtask(() {
        if (mounted) {
          context.read<StocktakeListCubit>().load();
        }
      });
    }
    _wasCurrent = isCurrent;
  }

  List<K7Column<StocktakeListRow>> _columns(BuildContext context) {
    final colors = context.vColors;
    return [
      K7Column<StocktakeListRow>(
        label: 'Phiên',
        cell: (row) => Text(
          row.code,
          style: VTypography.monoNumeric.copyWith(color: colors.textPrimary),
        ),
      ),
      K7Column<StocktakeListRow>(
        label: 'Phạm vi',
        cell: (row) => VText(
          row.scopeLabel,
          variant: VTextVariant.bodyDefault,
          color: colors.textPrimary,
        ),
      ),
      K7Column<StocktakeListRow>(
        label: 'Người đếm',
        cell: (row) => VText(
          row.counterName,
          variant: VTextVariant.bodyDefault,
          color: colors.textPrimary,
        ),
      ),
      K7Column<StocktakeListRow>(
        label: 'Đã đếm',
        numeric: true,
        cell: (row) => Text(
          row.status == StocktakeStatus.counting
              ? '${row.countedCount}/${row.lineCount}'
              : '${row.varianceCount} lệch',
          style: VTypography.monoNumeric.copyWith(color: colors.textPrimary),
        ),
      ),
      K7Column<StocktakeListRow>(
        label: 'Mở lúc',
        cell: (row) => Text(
          _formatOpenedAt(row.openedAt),
          style: VTypography.monoNumeric.copyWith(color: colors.textPrimary),
        ),
      ),
      K7Column<StocktakeListRow>(
        label: 'Tình trạng',
        cell: (row) {
          final badge = stocktakeStatusBadge(row.status);
          return VBadge(label: badge.$1, tone: badge.$2);
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<StocktakeListCubit>();
    final state = cubit.state;
    final isWide = inventoryIsWide(context);
    final showFooter = state.status == StocktakeListStatus.ready;

    return VPageScaffold(
      title: 'Kiểm kê kho',
      contentMaxWidth: isWide
          ? VPageScaffold.fullWidth
          : VPageScaffold.defaultContentMaxWidth,
      leading: widget.onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Quay về Kho',
              onPressed: widget.onBack,
            )
          : null,
      bottomBar: showFooter
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space4,
                vertical: VSpacing.space3,
              ),
              child: InventoryFooter(
                actions: [
                  InventoryFooterAction(
                    label: 'Tạo phiên kiểm kê',
                    primary: true,
                    onPressed: widget.onCreate,
                  ),
                ],
              ),
            )
          : null,
      body: Builder(
        builder: (context) {
          if (state.status == StocktakeListStatus.loading) {
            return const Padding(
              padding: EdgeInsets.all(VSpacing.space4),
              child: InventoryLoading(
                blocks: [
                  InventorySkeletonBlock.search,
                  InventorySkeletonBlock.row,
                  InventorySkeletonBlock.row,
                  InventorySkeletonBlock.row,
                ],
              ),
            );
          }

          if (state.status == StocktakeListStatus.loadError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: InventoryEmpty(
                  title: 'Không tải được danh sách kiểm kê',
                  description:
                      state.errorMessage ?? 'Kiểm tra kết nối rồi thử lại.',
                  actionLabel: 'Thử lại',
                  onAction: cubit.load,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: cubit.load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(VSpacing.space4),
              child: K6TaskList<StocktakeListRow>(
                search: K6Search(
                  value: state.query,
                  hint: 'Tìm phiên kiểm kê',
                  onChanged: cubit.setQuery,
                ),
                filters: K7FilterChips(
                  items: [
                    for (final f in StocktakeListFilter.values)
                      K7Filter(
                        key: f.key,
                        label: f.label,
                        count: state.counts[f] ?? 0,
                      ),
                  ],
                  selected: state.filter.key,
                  onSelected: (key) =>
                      cubit.setFilter(StocktakeListFilter.fromKey(key)),
                ),
                columns: _columns(context),
                rows: state.visible,
                total: state.all.length,
                title: (row) => row.code,
                subtitle: stocktakeListSubtitle,
                status: (row) {
                  final badge = stocktakeStatusBadge(row.status);
                  return K6Status(label: badge.$1, tone: badge.$2);
                },
                onOpen: widget.onOpen,
                empty: const InventoryEmpty(
                  title: 'Chưa có phiên kiểm kê',
                  description: 'Tạo phiên để đếm toàn kho hoặc một nhóm hàng.',
                ),
                filterEmpty: InventoryEmpty(
                  title: 'Không tìm thấy phiên kiểm kê',
                  description: 'Thử từ khóa hoặc bộ lọc khác.',
                  actionLabel: 'Xem tất cả',
                  onAction: cubit.clearFilter,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

