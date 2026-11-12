import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/logic/costing/costing_rules.dart';
import 'package:erp/features/inventory/logic/reports/gross_profit_cubit.dart';
import 'package:erp/features/inventory/logic/reports/gross_profit_state.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';
import 'package:erp/features/inventory/logic/reports/reports_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/reports/gross_profit_product_sheet.dart';
import 'package:erp/features/inventory/presentation/reports/report_period_sheet.dart';
import 'package:erp/features/inventory/presentation/reports/reports_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

/// Báo cáo lãi gộp (chỉ chủ cửa hàng): theo sản phẩm hoặc theo đơn.
class GrossProfitPage extends StatelessWidget {
  const GrossProfitPage({
    super.key,
    this.initialPeriod,
    this.initialMode = GrossProfitMode.product,
    this.onOpenOrder,
    this.onBack,
    this.clock,
  });

  final ReportPeriod? initialPeriod;
  final GrossProfitMode initialMode;
  final ValueChanged<String>? onOpenOrder;
  final VoidCallback? onBack;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final today = (clock ?? DateTime.now)();
    return BlocProvider(
      create: (ctx) => GrossProfitCubit(
        resolveReportsRepository(ctx),
        initialPeriod ?? ReportPeriod.thisMonth(today),
        initialMode,
      )..load(),
      child: _GrossProfitView(
        onOpenOrder: onOpenOrder,
        onBack: onBack,
        clock: clock ?? DateTime.now,
      ),
    );
  }
}

class _GrossProfitView extends StatelessWidget {
  const _GrossProfitView({
    required this.onOpenOrder,
    required this.onBack,
    required this.clock,
  });

  final ValueChanged<String>? onOpenOrder;
  final VoidCallback? onBack;
  final DateTime Function() clock;

  void _back(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    context.go('/warehouse');
  }

  void _openOrder(BuildContext context, GrossProfitOrderRow row) {
    if (onOpenOrder != null) {
      onOpenOrder!(row.orderId);
      return;
    }
    context.push('/sales/orders/${row.orderId}');
  }

  Future<void> _pickPeriod(BuildContext context, GrossProfitCubit cubit) async {
    final picked = await ReportPeriodSheet.show(
      context,
      current: cubit.state.period,
      today: clock(),
    );
    if (picked != null) await cubit.setPeriod(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<GrossProfitCubit>();
    final state = cubit.state;
    final isWide = inventoryIsWide(context);

    return VPageScaffold(
      title: 'Lãi gộp',
      contentMaxWidth: isWide
          ? VPageScaffold.fullWidth
          : VPageScaffold.defaultContentMaxWidth,
      leading: reportBackButton(() => _back(context), tooltip: 'Quay về Kho'),
      body: _body(context, cubit, state, isWide),
    );
  }

  Widget _body(
    BuildContext context,
    GrossProfitCubit cubit,
    GrossProfitState state,
    bool isWide,
  ) {
    if (state.status == ReportStatus.denied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: InventoryDenied(
            what: 'xem lãi gộp',
            next: 'Chỉ chủ cửa hàng xem báo cáo lãi gộp.',
            onExit: () => _back(context),
          ),
        ),
      );
    }

    final isProduct = state.mode == GrossProfitMode.product;
    final asOf = isProduct ? state.byProduct?.asOf : state.byOrder?.asOf;
    final segmented = VSegmentedControl(
      segments: const ['Theo sản phẩm', 'Theo đơn'],
      selectedIndex: isProduct ? 0 : 1,
      onChanged: (i) => cubit.setMode(
        i == 0 ? GrossProfitMode.product : GrossProfitMode.order,
      ),
    );

    final hasData = isProduct ? state.byProduct != null : state.byOrder != null;
    Widget content;
    if (state.status == ReportStatus.loading && !hasData) {
      content = const InventoryLoading(
        blocks: [
          InventorySkeletonBlock.row,
          InventorySkeletonBlock.row,
          InventorySkeletonBlock.row,
        ],
      );
    } else if (state.status == ReportStatus.error || !hasData) {
      content = InventoryEmpty(
        title: state.message ?? 'Không tải được báo cáo lãi gộp.',
        description: 'Kiểm tra kết nối rồi thử lại.',
        actionLabel: 'Thử lại',
        onAction: cubit.load,
      );
    } else if (isProduct) {
      content = _productContent(context, state.byProduct!, isWide);
    } else {
      content = _orderContent(context, state.byOrder!, isWide);
    }

    return RefreshIndicator(
      onRefresh: cubit.load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReportPeriodBar(
              period: state.period,
              asOf: asOf,
              onTap: () => _pickPeriod(context, cubit),
              trailing: isWide ? Align(alignment: Alignment.centerLeft, child: SizedBox(width: 320, child: segmented)) : null,
            ),
            if (!isWide) ...[
              const SizedBox(height: VSpacing.space3),
              segmented,
            ],
            const SizedBox(height: VSpacing.space3),
            content,
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => const InventoryEmpty(
        title: 'Chưa có đơn bán trong kỳ',
        description: 'Đổi khoảng ngày để xem dữ liệu khác.',
      );

  Widget _totalsCard(List<(String, String, bool)> rows) {
    return VCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in rows)
            VKeyValueRow(label: r.$1, value: r.$2, mono: true, emphasized: r.$3),
        ],
      ),
    );
  }

  // ----- Theo sản phẩm -----------------------------------------------------

  Widget _productContent(
    BuildContext context,
    GrossProfitByProduct data,
    bool isWide,
  ) {
    if (data.rows.isEmpty && data.lossVnd == 0) return _emptyState();
    final t = data.totals;
    final totals = _totalsCard([
      ('Doanh thu thuần', MoneyFormatter.formatMinor(t.netRevenue), false),
      ('Giá vốn', MoneyFormatter.formatMinor(t.cogsAfter), false),
      ('Lãi gộp', signedMoney(t.grossProfit), true),
      ('Hao hụt / huỷ', MoneyFormatter.formatMinor(t.loss), false),
      ('Lãi sau hao hụt', signedMoney(t.profitAfterLoss), true),
    ]);

    final Widget list;
    if (data.rows.isEmpty) {
      list = _emptyState();
    } else if (isWide) {
      list = K7Table<GrossProfitRow>(
        columns: _productColumns(),
        rows: data.rows,
        mobileRow: (r) => _productRow(context, r),
        onRowTap: (r) => showGrossProfitProductSheet(context, r),
      );
    } else {
      list = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < data.rows.length; i++) ...[
            _productRow(context, data.rows[i]),
            if (i < data.rows.length - 1) const SizedBox(height: VSpacing.space2),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        totals,
        const SizedBox(height: VSpacing.space3),
        list,
      ],
    );
  }

  Widget _productRow(BuildContext context, GrossProfitRow r) {
    return VListRow(
      title: r.name,
      subtitle: 'DT ${MoneyFormatter.formatMinor(r.netRevenueVnd)} · '
          'GV ${MoneyFormatter.formatMinor(r.cogsAfterVnd)}\n'
          'Lãi ${signedMoney(r.grossProfitVnd)} · ${marginText(r.marginPct)}',
      onTap: () => showGrossProfitProductSheet(context, r),
    );
  }

  List<K7Column<GrossProfitRow>> _productColumns() {
    Widget num(String text, {bool bold = false}) =>
        Builder(builder: (ctx) => reportNumberCell(ctx, text, bold: bold));
    return [
      K7Column<GrossProfitRow>(
        label: 'Sản phẩm',
        cell: (r) => Builder(
          builder: (ctx) => reportProductCell(
            ctx,
            name: r.name,
            sub: [r.code, r.uom].where((e) => e.isNotEmpty).join(' · '),
          ),
        ),
      ),
      K7Column<GrossProfitRow>(
        label: 'Doanh thu thuần',
        numeric: true,
        cell: (r) => num(MoneyFormatter.formatMinor(r.netRevenueVnd)),
      ),
      K7Column<GrossProfitRow>(
        label: 'Giá vốn lúc bán',
        numeric: true,
        cell: (r) => num(MoneyFormatter.formatMinor(r.cogsAtSaleVnd)),
      ),
      K7Column<GrossProfitRow>(
        label: 'Điều chỉnh',
        numeric: true,
        cell: (r) => num(signedMoney(r.cogsAdjustVnd)),
      ),
      K7Column<GrossProfitRow>(
        label: 'Chiết khấu NCC',
        numeric: true,
        cell: (r) => num(rebateText(r.rebateVnd)),
      ),
      K7Column<GrossProfitRow>(
        label: 'Giá vốn sau điều chỉnh',
        numeric: true,
        cell: (r) => num(MoneyFormatter.formatMinor(r.cogsAfterVnd)),
      ),
      K7Column<GrossProfitRow>(
        label: 'Lãi gộp',
        numeric: true,
        cell: (r) => num(signedMoney(r.grossProfitVnd), bold: true),
      ),
      K7Column<GrossProfitRow>(
        label: 'Tỷ lệ',
        numeric: true,
        cell: (r) => num(marginText(r.marginPct)),
      ),
    ];
  }

  // ----- Theo đơn ---------------------------------------------------------

  Widget _orderContent(
    BuildContext context,
    GrossProfitByOrder data,
    bool isWide,
  ) {
    if (data.rows.isEmpty) return _emptyState();
    final t = data.totals;
    final totals = _totalsCard([
      ('Doanh thu', MoneyFormatter.formatMinor(t.revenue), false),
      ('Giá vốn', MoneyFormatter.formatMinor(t.cogs), false),
      ('Lãi gộp', signedMoney(t.grossProfit), true),
    ]);

    final Widget list;
    if (isWide) {
      list = K7Table<GrossProfitOrderRow>(
        columns: _orderColumns(),
        rows: data.rows,
        mobileRow: (r) => _orderRow(context, r),
        onRowTap: (r) => _openOrder(context, r),
      );
    } else {
      list = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < data.rows.length; i++) ...[
            _orderRow(context, data.rows[i]),
            if (i < data.rows.length - 1) const SizedBox(height: VSpacing.space2),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        totals,
        const SizedBox(height: VSpacing.space3),
        list,
        const SizedBox(height: VSpacing.space3),
        const ReportNote('Điều chỉnh giá vốn không chia xuống từng đơn.'),
      ],
    );
  }

  Widget _orderRow(BuildContext context, GrossProfitOrderRow r) {
    return VListRow(
      title: r.orderCode,
      subtitle: '${reportDate(r.completedOn)} · '
          'DT ${MoneyFormatter.formatMinor(r.revenueVnd)} · '
          'GV ${MoneyFormatter.formatMinor(r.cogsVnd)}',
      onTap: () => _openOrder(context, r),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            signedMoney(r.grossProfitVnd),
            style: VTypography.monoNumeric.copyWith(
              color: context.vColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (r.hasProvisional) ...[
            const SizedBox(height: 2),
            const VBadge(label: 'Giá tạm', tone: VComponentTone.warning),
          ],
        ],
      ),
    );
  }

  List<K7Column<GrossProfitOrderRow>> _orderColumns() {
    Widget num(String text, {bool bold = false}) =>
        Builder(builder: (ctx) => reportNumberCell(ctx, text, bold: bold));
    return [
      K7Column<GrossProfitOrderRow>(
        label: 'Đơn',
        cell: (r) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (ctx) => Text(
                r.orderCode,
                style: VTypography.monoNumeric.copyWith(
                  color: ctx.vColors.textPrimary,
                ),
              ),
            ),
            if (r.hasProvisional) ...[
              const SizedBox(width: VSpacing.space2),
              const VBadge(label: 'Giá tạm', tone: VComponentTone.warning),
            ],
          ],
        ),
      ),
      K7Column<GrossProfitOrderRow>(
        label: 'Ngày',
        cell: (r) => Builder(
          builder: (ctx) => Text(
            reportDate(r.completedOn),
            style: VTypography.monoNumeric.copyWith(color: ctx.vColors.textPrimary),
          ),
        ),
      ),
      K7Column<GrossProfitOrderRow>(
        label: 'Doanh thu',
        numeric: true,
        cell: (r) => num(MoneyFormatter.formatMinor(r.revenueVnd)),
      ),
      K7Column<GrossProfitOrderRow>(
        label: 'Giá vốn lúc bán',
        numeric: true,
        cell: (r) => num(MoneyFormatter.formatMinor(r.cogsVnd)),
      ),
      K7Column<GrossProfitOrderRow>(
        label: 'Lãi gộp',
        numeric: true,
        cell: (r) => num(signedMoney(r.grossProfitVnd), bold: true),
      ),
      K7Column<GrossProfitOrderRow>(
        label: 'Tỷ lệ',
        numeric: true,
        cell: (r) => num(marginText(r.marginPct)),
      ),
    ];
  }
}
