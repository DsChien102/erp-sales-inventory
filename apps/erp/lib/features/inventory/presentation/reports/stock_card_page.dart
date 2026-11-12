import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';
import 'package:erp/features/inventory/logic/reports/reports_rules.dart';
import 'package:erp/features/inventory/logic/reports/stock_card_cubit.dart';
import 'package:erp/features/inventory/logic/reports/stock_card_state.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/reports/report_period_sheet.dart';
import 'package:erp/features/inventory/presentation/reports/reports_ui.dart';
import 'package:erp/features/inventory/presentation/reports/stock_card_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

const _allLotsKey = 'ALL';

/// Một dòng hiển thị của thẻ kho: dòng cạnh ("Tồn đầu kỳ" / "Tồn cuối kỳ") hoặc dòng biến động.
class _CardEntry {
  const _CardEntry.edge(this.edgeLabel, this.edgeValue) : line = null;
  const _CardEntry.line(this.line)
      : edgeLabel = null,
        edgeValue = null;

  final String? edgeLabel;
  final num? edgeValue;
  final StockCardLine? line;

  bool get isEdge => line == null;
}

/// SCR-055: Thẻ kho của một sản phẩm.
class StockCardPage extends StatelessWidget {
  const StockCardPage({
    super.key,
    required this.productId,
    this.initialPeriod,
    this.fromStock = false,
    this.onOpenMovement,
    this.onBack,
    this.clock,
  });

  final String productId;
  final ReportPeriod? initialPeriod;

  /// `?back=stock` ⇒ quay lại màn tồn kho của sản phẩm.
  final bool fromStock;
  final ValueChanged<StockCardLine>? onOpenMovement;
  final VoidCallback? onBack;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final today = (clock ?? DateTime.now)();
    return BlocProvider(
      create: (ctx) => StockCardCubit(
        resolveReportsRepository(ctx),
        productId,
        initialPeriod ?? ReportPeriod.thisMonth(today),
      )..load(),
      child: _StockCardView(
        productId: productId,
        fromStock: fromStock,
        onOpenMovement: onOpenMovement,
        onBack: onBack,
        clock: clock ?? DateTime.now,
      ),
    );
  }
}

class _StockCardView extends StatelessWidget {
  const _StockCardView({
    required this.productId,
    required this.fromStock,
    required this.onOpenMovement,
    required this.onBack,
    required this.clock,
  });

  final String productId;
  final bool fromStock;
  final ValueChanged<StockCardLine>? onOpenMovement;
  final VoidCallback? onBack;
  final DateTime Function() clock;

  void _back(BuildContext context, ReportPeriod period) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (fromStock) {
      context.go('/warehouse/stock/$productId');
      return;
    }
    final query = Uri(queryParameters: period.toQuery()).query;
    context.go('/warehouse/reports/stock?$query');
  }

  void _openMovement(BuildContext context, StockCardLine line) {
    if (onOpenMovement != null) {
      onOpenMovement!(line);
      return;
    }
    context.push('/warehouse/movements/${line.movementId}');
  }

  Future<void> _pickPeriod(BuildContext context, StockCardCubit cubit) async {
    final picked = await ReportPeriodSheet.show(
      context,
      current: cubit.state.period,
      today: clock(),
    );
    if (picked != null) {
      await cubit.setPeriod(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<StockCardCubit>();
    final state = cubit.state;
    final data = state.data;
    final isWide = inventoryIsWide(context);
    final product = data?.product;
    final subtitle = product == null
        ? null
        : [product.name, product.code, product.uom]
            .where((e) => e.isNotEmpty)
            .join(' · ');

    return VPageScaffold(
      title: 'Thẻ kho',
      subtitle: subtitle,
      contentMaxWidth: isWide
          ? VPageScaffold.fullWidth
          : VPageScaffold.defaultContentMaxWidth,
      leading: reportBackButton(() => _back(context, state.period)),
      body: _body(context, cubit, state, data),
    );
  }

  Widget _body(
    BuildContext context,
    StockCardCubit cubit,
    StockCardState state,
    StockCard? data,
  ) {
    if (state.status == ReportStatus.denied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: InventoryDenied(
            what: 'xem thẻ kho',
            next: 'Liên hệ chủ cửa hàng để được cấp quyền xem Kho.',
            onExit: () => _back(context, state.period),
          ),
        ),
      );
    }

    Widget content;
    if (state.status == ReportStatus.loading && data == null) {
      content = const InventoryLoading(
        blocks: [
          InventorySkeletonBlock.search,
          InventorySkeletonBlock.card,
          InventorySkeletonBlock.row,
          InventorySkeletonBlock.row,
        ],
      );
    } else if (state.status == ReportStatus.error || data == null) {
      content = InventoryEmpty(
        title: state.message ?? 'Không tải được thẻ kho.',
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

  Widget _lotChips(StockCardCubit cubit, StockCardState state, StockCard data) {
    if (!data.product.isLotTracked) {
      return const ReportNote('Sản phẩm không quản lý theo lô.');
    }
    final totalAllLots = data.lots.fold<num>(0, (a, l) => a + l.closingQty);
    return K7FilterChips(
      items: [
        K7Filter(
          key: _allLotsKey,
          label: 'Tất cả lô',
          count: totalAllLots.round(),
        ),
        for (final l in data.lots)
          K7Filter(
            key: l.lotId,
            label: 'Lô ${l.lotCode}',
            count: l.closingQty.round(),
          ),
      ],
      selected: state.lotId ?? _allLotsKey,
      onSelected: (key) => cubit.selectLot(key == _allLotsKey ? null : key),
    );
  }

  Widget _loaded(
    BuildContext context,
    StockCardCubit cubit,
    StockCardState state,
    StockCard data,
  ) {
    final chips = _lotChips(cubit, state, data);
    final hasLotFilter = state.lotId != null;
    final head = <Widget>[
      chips,
      const SizedBox(height: VSpacing.space3),
      StockCardStrip(summary: data.summary),
      if (data.closingValue != null) ...[
        const SizedBox(height: VSpacing.space3),
        ReportTotalLine(
          label: 'Giá trị cuối kỳ',
          value: MoneyFormatter.formatMinor(data.closingValue!),
        ),
      ],
      const SizedBox(height: VSpacing.space3),
    ];

    if (data.rows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...head,
          InventoryEmpty(
            title: 'Không có biến động trong kỳ',
            description: 'Đổi khoảng ngày hoặc sản phẩm để xem dữ liệu khác.',
            actionLabel: hasLotFilter ? 'Xem tất cả' : 'Xem tháng trước',
            onAction: () {
              if (hasLotFilter) {
                cubit.selectLot(null);
              } else {
                cubit.setPeriod(ReportPeriod.lastMonth(clock()));
              }
            },
          ),
        ],
      );
    }

    final entries = <_CardEntry>[
      _CardEntry.edge('Tồn đầu kỳ', data.summary.openingQty),
      for (final l in data.rows) _CardEntry.line(l),
      _CardEntry.edge('Tồn cuối kỳ', data.summary.closingQty),
    ];
    final tracked = data.product.isLotTracked;
    final uom = data.product.uom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...head,
        K7Table<_CardEntry>(
          columns: _columns(tracked),
          rows: entries,
          mobileRow: (e) => _mobileRow(context, e, tracked, uom),
          onRowTap: (e) {
            if (e.line != null) _openMovement(context, e.line!);
          },
        ),
      ],
    );
  }

  List<K7Column<_CardEntry>> _columns(bool tracked) {
    Widget text(BuildContext ctx, String s, {bool bold = false, bool mono = false}) {
      final base = mono ? VTypography.monoNumeric : VTypography.bodyDefault;
      return Text(
        s,
        style: base.copyWith(
          color: ctx.vColors.textPrimary,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      );
    }

    return [
      K7Column<_CardEntry>(
        label: 'Ngày nghiệp vụ',
        cell: (e) => Builder(
          builder: (ctx) => text(
            ctx,
            e.line == null ? '' : reportDate(e.line!.businessDate),
            mono: true,
          ),
        ),
      ),
      K7Column<_CardEntry>(
        label: 'Chứng từ',
        cell: (e) => Builder(
          builder: (ctx) => text(ctx, e.line?.docCode ?? '', mono: true),
        ),
      ),
      K7Column<_CardEntry>(
        label: 'Diễn giải',
        cell: (e) => Builder(
          builder: (ctx) {
            final l = e.line;
            return text(
              ctx,
              l == null
                  ? e.edgeLabel!
                  : movementLabel(l.movementKind, l.intentType, l.reason),
              bold: l == null,
            );
          },
        ),
      ),
      if (tracked)
        K7Column<_CardEntry>(
          label: 'Lô',
          cell: (e) => Builder(
            builder: (ctx) => text(ctx, e.line == null ? '' : (e.line!.lotCode ?? '—')),
          ),
        ),
      K7Column<_CardEntry>(
        label: 'Nhập',
        numeric: true,
        cell: (e) => Builder(
          builder: (ctx) => reportNumberCell(
            ctx,
            e.line != null && e.line!.quantityDelta > 0
                ? formatQuantity(e.line!.quantityDelta.toDouble())
                : '',
          ),
        ),
      ),
      K7Column<_CardEntry>(
        label: 'Xuất',
        numeric: true,
        cell: (e) => Builder(
          builder: (ctx) => reportNumberCell(
            ctx,
            e.line != null && e.line!.quantityDelta < 0
                ? formatQuantity(-e.line!.quantityDelta.toDouble())
                : '',
          ),
        ),
      ),
      K7Column<_CardEntry>(
        label: 'Tồn',
        numeric: true,
        cell: (e) => Builder(
          builder: (ctx) => reportNumberCell(
            ctx,
            formatQuantity((e.line?.balanceAfter ?? e.edgeValue!).toDouble()),
            bold: e.isEdge,
          ),
        ),
      ),
    ];
  }

  Widget _mobileRow(BuildContext context, _CardEntry e, bool tracked, String uom) {
    final colors = context.vColors;
    final line = e.line;
    if (line == null) {
      return Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space4,
          vertical: VSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(VRadius.r12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              e.edgeLabel!,
              style: VTypography.bodySmall.copyWith(
                color: colors.textSecondary,
                height: 20 / 13,
              ),
            ),
            Text(
              formatStockQuantity(e.edgeValue!, uom),
              style: VTypography.monoNumeric.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final label = movementLabel(line.movementKind, line.intentType, line.reason);
    final sub = [
      reportDate(line.businessDate),
      if (tracked && line.lotCode != null) 'Lô ${line.lotCode}',
      if (line.actorName.isNotEmpty) line.actorName,
    ].join(' · ');
    return VListRow(
      title: line.docCode.isEmpty ? label : '$label ${line.docCode}',
      subtitle: sub,
      onTap: () => _openMovement(context, line),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            signedQty(line.quantityDelta),
            style: VTypography.monoNumeric.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Tồn ${formatQuantity(line.balanceAfter.toDouble())}',
            style: VTypography.monoNumeric.copyWith(
              color: colors.textSecondary,
              fontSize: 12,
              height: 16 / 12,
            ),
          ),
        ],
      ),
    );
  }
}
