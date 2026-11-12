import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';
import 'package:erp/features/inventory/logic/reports/supplier_purchase_cubit.dart';
import 'package:erp/features/inventory/logic/reports/supplier_purchase_state.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/reports/report_period_sheet.dart';
import 'package:erp/features/inventory/presentation/reports/reports_ui.dart';
import 'package:erp/features/inventory/presentation/reports/supplier_purchase_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

/// Báo cáo nhập hàng theo nhà cung cấp (chỉ chủ cửa hàng).
class SupplierPurchasePage extends StatelessWidget {
  const SupplierPurchasePage({
    super.key,
    this.initialPeriod,
    this.onBack,
    this.clock,
  });

  final ReportPeriod? initialPeriod;
  final VoidCallback? onBack;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final today = (clock ?? DateTime.now)();
    return BlocProvider(
      create: (ctx) => SupplierPurchaseCubit(
        resolveReportsRepository(ctx),
        initialPeriod ?? ReportPeriod.thisMonth(today),
      )..load(),
      child: _SupplierPurchaseView(
        onBack: onBack,
        clock: clock ?? DateTime.now,
      ),
    );
  }
}

class _SupplierPurchaseView extends StatelessWidget {
  const _SupplierPurchaseView({required this.onBack, required this.clock});

  final VoidCallback? onBack;
  final DateTime Function() clock;

  void _back(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    context.go('/warehouse');
  }

  Future<void> _pickPeriod(
    BuildContext context,
    SupplierPurchaseCubit cubit,
  ) async {
    final picked = await ReportPeriodSheet.show(
      context,
      current: cubit.state.period,
      today: clock(),
    );
    if (picked != null) await cubit.setPeriod(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SupplierPurchaseCubit>();
    final state = cubit.state;
    final isWide = inventoryIsWide(context);

    return VPageScaffold(
      title: 'Nhập hàng theo NCC',
      contentMaxWidth: isWide
          ? VPageScaffold.fullWidth
          : VPageScaffold.defaultContentMaxWidth,
      leading: reportBackButton(() => _back(context), tooltip: 'Quay về Kho'),
      body: _body(context, cubit, state, isWide),
    );
  }

  Widget _body(
    BuildContext context,
    SupplierPurchaseCubit cubit,
    SupplierPurchaseState state,
    bool isWide,
  ) {
    if (state.status == ReportStatus.denied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: InventoryDenied(
            what: 'xem báo cáo nhập hàng',
            next: 'Chỉ chủ cửa hàng xem báo cáo nhập hàng.',
            onExit: () => _back(context),
          ),
        ),
      );
    }

    final data = state.data;
    Widget content;
    if (state.status == ReportStatus.loading && data == null) {
      content = const InventoryLoading(
        blocks: [
          InventorySkeletonBlock.row,
          InventorySkeletonBlock.row,
          InventorySkeletonBlock.row,
        ],
      );
    } else if (state.status == ReportStatus.error || data == null) {
      content = InventoryEmpty(
        title: state.message ?? 'Không tải được báo cáo nhập hàng theo NCC.',
        description: 'Kiểm tra kết nối rồi thử lại.',
        actionLabel: 'Thử lại',
        onAction: cubit.load,
      );
    } else if (data.suppliers.isEmpty) {
      content = const InventoryEmpty(
        title: 'Chưa nhập hàng trong kỳ',
        description: 'Đổi khoảng ngày để xem dữ liệu khác.',
      );
    } else {
      content = _list(context, data, isWide);
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
              asOf: data?.asOf,
              onTap: () => _pickPeriod(context, cubit),
            ),
            const SizedBox(height: VSpacing.space3),
            content,
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, SupplierPurchaseReport data, bool isWide) {
    final Widget rows;
    if (isWide) {
      rows = K7Table<SupplierPurchaseRow>(
        columns: _columns(),
        rows: data.suppliers,
        mobileRow: (s) => _mobileRow(context, s),
        onRowTap: (s) => showSupplierPurchaseSheet(context, s),
      );
    } else {
      rows = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < data.suppliers.length; i++) ...[
            _mobileRow(context, data.suppliers[i]),
            if (i < data.suppliers.length - 1)
              const SizedBox(height: VSpacing.space2),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportTotalLine(
          label: 'Tổng giá gốc',
          value: MoneyFormatter.formatMinor(data.totals.landed),
        ),
        const SizedBox(height: VSpacing.space3),
        rows,
      ],
    );
  }

  Widget _mobileRow(BuildContext context, SupplierPurchaseRow s) {
    return VListRow(
      title: s.name,
      subtitle: 'Giá gốc ${MoneyFormatter.formatMinor(s.landedVnd)}',
      trailing: Text(
        '${s.receiptCount} phiếu',
        style: VTypography.bodyDefault.copyWith(
          color: context.vColors.textSecondary,
        ),
      ),
      onTap: () => showSupplierPurchaseSheet(context, s),
    );
  }

  List<K7Column<SupplierPurchaseRow>> _columns() {
    Widget num(String text, {bool bold = false}) =>
        Builder(builder: (ctx) => reportNumberCell(ctx, text, bold: bold));
    return [
      K7Column<SupplierPurchaseRow>(
        label: 'Nhà cung cấp',
        cell: (s) => Builder(
          builder: (ctx) => Text(
            s.name,
            style: VTypography.bodyDefault.copyWith(
              color: ctx.vColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      K7Column<SupplierPurchaseRow>(
        label: 'Số phiếu',
        numeric: true,
        cell: (s) => num('${s.receiptCount}'),
      ),
      K7Column<SupplierPurchaseRow>(
        label: 'Tiền mua',
        numeric: true,
        cell: (s) => num(MoneyFormatter.formatMinor(s.purchaseVnd)),
      ),
      K7Column<SupplierPurchaseRow>(
        label: 'Chi phí thu mua',
        numeric: true,
        cell: (s) => num(MoneyFormatter.formatMinor(s.freightVnd)),
      ),
      K7Column<SupplierPurchaseRow>(
        label: 'Chiết khấu thương mại',
        numeric: true,
        cell: (s) => num(MoneyFormatter.formatMinor(s.tradeDiscountVnd)),
      ),
      K7Column<SupplierPurchaseRow>(
        label: 'Giá gốc',
        numeric: true,
        cell: (s) => num(MoneyFormatter.formatMinor(s.landedVnd), bold: true),
      ),
      K7Column<SupplierPurchaseRow>(
        label: 'Chiết khấu đạt mốc',
        numeric: true,
        cell: (s) => num(
          s.rebateVnd > 0 ? MoneyFormatter.formatMinor(s.rebateVnd) : '—',
        ),
      ),
    ];
  }
}
