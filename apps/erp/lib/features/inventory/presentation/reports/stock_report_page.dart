import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';
import 'package:erp/features/inventory/logic/reports/stock_report_cubit.dart';
import 'package:erp/features/inventory/logic/reports/stock_report_state.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/patterns/k6_task_list.dart';
import 'package:erp/features/inventory/presentation/reports/report_period_sheet.dart';
import 'package:erp/features/inventory/presentation/reports/reports_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

/// SCR-055: Báo cáo nhập – xuất – tồn.
class StockReportPage extends StatelessWidget {
  const StockReportPage({
    super.key,
    this.initialPeriod,
    this.onOpenProduct,
    this.onBack,
    this.clock,
  });

  final ReportPeriod? initialPeriod;

  /// Mở thẻ kho của sản phẩm với kỳ đang xem.
  final void Function(StockReportRow row, ReportPeriod period)? onOpenProduct;
  final VoidCallback? onBack;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final today = (clock ?? DateTime.now)();
    return BlocProvider(
      create: (ctx) => StockReportCubit(
        resolveReportsRepository(ctx),
        initialPeriod ?? ReportPeriod.thisMonth(today),
      )..load(),
      child: _StockReportView(
        onOpenProduct: onOpenProduct,
        onBack: onBack,
        clock: clock ?? DateTime.now,
      ),
    );
  }
}

class _StockReportView extends StatelessWidget {
  const _StockReportView({
    required this.onOpenProduct,
    required this.onBack,
    required this.clock,
  });

  final void Function(StockReportRow row, ReportPeriod period)? onOpenProduct;
  final VoidCallback? onBack;
  final DateTime Function() clock;

  void _back(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    context.go('/warehouse');
  }

  void _open(BuildContext context, StockReportRow row, ReportPeriod period) {
    if (onOpenProduct != null) {
      onOpenProduct!(row, period);
      return;
    }
    final query = Uri(queryParameters: period.toQuery()).query;
    context.push('/warehouse/reports/stock/${row.productId}?$query');
  }

  Future<void> _pickPeriod(BuildContext context, StockReportCubit cubit) async {
    final picked = await ReportPeriodSheet.show(
      context,
      current: cubit.state.period,
      today: clock(),
    );
    if (picked != null) {
      await cubit.setPeriod(picked);
    }
  }

  List<K7Column<StockReportRow>> _columns(StockReport data) {
    return [
      K7Column<StockReportRow>(
        label: 'Sản phẩm',
        cell: (r) => Builder(
          builder: (ctx) => reportProductCell(
            ctx,
            name: r.name,
            sub: [r.code, r.uom].where((e) => e.isNotEmpty).join(' · '),
          ),
        ),
      ),
      K7Column<StockReportRow>(
        label: 'Đầu kỳ',
        numeric: true,
        cell: (r) => Builder(
          builder: (ctx) =>
              reportNumberCell(ctx, formatQuantity(r.openingQty.toDouble())),
        ),
      ),
      K7Column<StockReportRow>(
        label: 'Nhập',
        numeric: true,
        cell: (r) => Builder(
          builder: (ctx) =>
              reportNumberCell(ctx, formatQuantity(r.inQty.toDouble())),
        ),
      ),
      K7Column<StockReportRow>(
        label: 'Xuất',
        numeric: true,
        cell: (r) => Builder(
          builder: (ctx) =>
              reportNumberCell(ctx, formatQuantity(r.outQty.toDouble())),
        ),
      ),
      K7Column<StockReportRow>(
        label: 'Cuối kỳ',
        numeric: true,
        cell: (r) => Builder(
          builder: (ctx) => reportNumberCell(
            ctx,
            formatQuantity(r.closingQty.toDouble()),
            bold: true,
          ),
        ),
      ),
      if (data.showAvailable)
        K7Column<StockReportRow>(
          label: 'Khả dụng',
          numeric: true,
          cell: (r) => Builder(
            builder: (ctx) => reportNumberCell(
              ctx,
              r.available == null
                  ? '—'
                  : formatQuantity(r.available!.toDouble()),
            ),
          ),
        ),
      if (!data.financialMasked)
        K7Column<StockReportRow>(
          label: 'Giá trị cuối kỳ',
          numeric: true,
          cell: (r) => Builder(
            builder: (ctx) => reportNumberCell(
              ctx,
              r.closingValue == null
                  ? '—'
                  : MoneyFormatter.formatMinor(r.closingValue!),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<StockReportCubit>();
    final state = cubit.state;
    final data = state.data;
    final isWide = inventoryIsWide(context);

    return VPageScaffold(
      title: 'Báo cáo nhập – xuất – tồn',
      contentMaxWidth: isWide
          ? VPageScaffold.fullWidth
          : VPageScaffold.defaultContentMaxWidth,
      leading: reportBackButton(() => _back(context), tooltip: 'Quay về Kho'),
      body: _body(context, cubit, state, data),
    );
  }

  Widget _body(
    BuildContext context,
    StockReportCubit cubit,
    StockReportState state,
    StockReport? data,
  ) {
    if (state.status == ReportStatus.denied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: InventoryDenied(
            what: 'xem báo cáo tồn',
            next: 'Liên hệ chủ cửa hàng để được cấp quyền xem Kho.',
            onExit: () => _back(context),
          ),
        ),
      );
    }

    final bar = ReportPeriodBar(
      period: state.period,
      asOf: data?.asOf,
      onTap: () => _pickPeriod(context, cubit),
    );

    Widget content;
    if (state.status == ReportStatus.loading && data == null) {
      content = const InventoryLoading(
        blocks: [
          InventorySkeletonBlock.search,
          InventorySkeletonBlock.row,
          InventorySkeletonBlock.row,
          InventorySkeletonBlock.row,
        ],
      );
    } else if (state.status == ReportStatus.error || data == null) {
      content = InventoryEmpty(
        title: state.message ?? 'Không tải được báo cáo nhập – xuất – tồn.',
        description: 'Kiểm tra kết nối rồi thử lại.',
        actionLabel: 'Thử lại',
        onAction: cubit.load,
      );
    } else {
      content = _loaded(context, cubit, state, data);
    }

    return RefreshIndicator(
      onRefresh: cubit.load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            bar,
            const SizedBox(height: VSpacing.space3),
            content,
          ],
        ),
      ),
    );
  }

  Widget _loaded(
    BuildContext context,
    StockReportCubit cubit,
    StockReportState state,
    StockReport data,
  ) {
    final hasSearch = state.search.trim().isNotEmpty;
    final rows = data.rows;
    final empty = InventoryEmpty(
      title: 'Không có biến động trong kỳ',
      description: 'Đổi khoảng ngày hoặc sản phẩm để xem dữ liệu khác.',
      actionLabel: hasSearch ? 'Xem tất cả' : 'Xem tháng trước',
      onAction: () {
        if (hasSearch) {
          cubit.search('');
        } else {
          cubit.setPeriod(ReportPeriod.lastMonth(clock()));
        }
      },
    );

    final list = K6TaskList<StockReportRow>(
      search: K6Search(
        value: state.search,
        hint: 'Tìm sản phẩm',
        onChanged: cubit.search,
      ),
      columns: _columns(data),
      rows: rows,
      // Có tìm mà không ra dòng nào: vẫn giữ ô tìm phía trên thông báo rỗng.
      total: rows.isEmpty ? (hasSearch ? 1 : 0) : rows.length,
      title: (r) => r.name,
      subtitle: (r) =>
          'Đầu ${formatQuantity(r.openingQty.toDouble())} · '
          'Nhập ${formatQuantity(r.inQty.toDouble())} · '
          'Xuất ${formatQuantity(r.outQty.toDouble())}',
      trailing: (r) => Builder(
        builder: (ctx) => Text(
          formatStockQuantity(r.closingQty, r.uom),
          style: VTypography.monoNumeric.copyWith(
            color: ctx.vColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onOpen: (r) => _open(context, r, state.period),
      empty: empty,
      filterEmpty: empty,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        list,
        if (rows.isNotEmpty) ...[
          if (!data.financialMasked && data.totalClosingValue != null) ...[
            const SizedBox(height: VSpacing.space3),
            ReportTotalLine(
              label: 'Tổng giá trị cuối kỳ',
              value: MoneyFormatter.formatMinor(data.totalClosingValue!),
            ),
          ],
          const SizedBox(height: VSpacing.space2),
          const ReportNote(
            'Không cộng các số lượng khác đơn vị thành một tổng giả.',
          ),
        ],
      ],
    );
  }
}
