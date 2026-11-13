import 'package:erp/features/inventory/data/models/lot_date.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:erp/features/inventory/logic/stock/stock_indicator_rules.dart';
import 'package:erp/features/inventory/presentation/costing/cost_versions_sheet.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/stock/stock_cost_block.dart';
import 'package:erp/features/inventory/presentation/stock/stock_lot_sheet.dart';
import 'package:erp/features/inventory/presentation/stock/stock_provenance_sheet.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

int _lotSortKey(LotDate? d) {
  if (d == null) return 99999999;
  final m = d.month ?? 12;
  final day = d.day ?? 31;
  return d.year * 10000 + m * 100 + day;
}

List<StockLot> sortStockLots(List<StockLot> lots) {
  final copy = List<StockLot>.from(lots);
  copy.sort((a, b) {
    final cmp = _lotSortKey(a.expiry).compareTo(_lotSortKey(b.expiry));
    if (cmp != 0) return cmp;
    return a.code.compareTo(b.code);
  });
  return copy;
}

class StockHeroCard extends StatelessWidget {
  final StockDetail detail;
  final VoidCallback? onEditThreshold;

  const StockHeroCard({
    super.key,
    required this.detail,
    this.onEditThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final inds = detail.indicators;
    StockIndicator? issue;
    if (inds.contains(StockIndicator.out)) {
      issue = StockIndicator.out;
    } else if (inds.contains(StockIndicator.low)) {
      issue = StockIndicator.low;
    }

    final hasNote = detail.expiredQuantity > 0;
    final hasPolicy = detail.threshold != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.r12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Khả dụng',
            style: TextStyle(
              fontSize: 13,
              height: 20 / 13,
              color: context.vColors.textSecondary,
            ),
          ),
          const SizedBox(height: VSpacing.space1),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatStockQuantity(detail.available, detail.uom),
                  style: TextStyle(
                    fontFamily: VTypography.monoFontFamily,
                    fontSize: 22,
                    height: 28 / 22,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (issue != null && issue.tone != null) ...[
                const SizedBox(width: VSpacing.space3),
                VBadge(
                  label: issue.label,
                  tone: issue.tone!,
                  showDot: true,
                  hollowDot: issue.tone == VComponentTone.danger,
                ),
              ],
            ],
          ),
          const SizedBox(height: VSpacing.space3),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tồn vật lý',
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: context.vColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: VSpacing.space1),
                    Text(
                      formatStockQuantity(detail.physical, detail.uom),
                      style: TextStyle(
                        fontFamily: VTypography.monoFontFamily,
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VSpacing.space3),
              const Expanded(child: SizedBox.shrink()),
              const SizedBox(width: VSpacing.space3),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
          if (hasNote) ...[
            const SizedBox(height: VSpacing.space3),
            Container(
              padding: const EdgeInsets.only(top: VSpacing.space3),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.borderDefault)),
              ),
              child: Text(
                'Không đủ điều kiện bán: Hết hạn ${formatStockQuantity(detail.expiredQuantity, detail.uom)}',
                style: TextStyle(
                  fontSize: 13,
                  height: 20 / 13,
                  color: context.vColors.textSecondary,
                ),
              ),
            ),
          ],
          if (hasPolicy) ...[
            const SizedBox(height: VSpacing.space3),
            Container(
              padding: EdgeInsets.only(top: hasNote ? 0 : VSpacing.space3),
              decoration: hasNote
                  ? null
                  : BoxDecoration(
                      border: Border(
                        top: BorderSide(color: colors.borderDefault),
                      ),
                    ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ngưỡng ${formatQuantity(detail.threshold!.toDouble())} · Mục tiêu ${formatStockQuantity(detail.target ?? detail.threshold!, detail.uom)}',
                      style: TextStyle(
                        fontSize: 13,
                        height: 20 / 13,
                        color: context.vColors.textSecondary,
                      ),
                    ),
                  ),
                  if (detail.isOwner && onEditThreshold != null) ...[
                    const SizedBox(width: VSpacing.space3),
                    MergeSemantics(
                      child: Semantics(
                        button: true,
                        child: InkWell(
                          onTap: onEditThreshold,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                            child: Center(
                              child: Text(
                                'Sửa ngưỡng',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 20 / 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textBrand,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StockDetailBody extends StatelessWidget {
  final StockDetail detail;
  final bool singleColumn;
  final VoidCallback? onEditThreshold;
  final VoidCallback? onReceive;
  final VoidCallback? onAdjustExpiredProduct;
  final ValueChanged<StockLot>? onAdjustExpiredLot;
  final VoidCallback? onOpenStockCard;
  final VoidCallback? onOpenReceipt;
  final VoidCallback? onCompareSuppliers;

  const StockDetailBody({
    super.key,
    required this.detail,
    this.singleColumn = false,
    this.onEditThreshold,
    this.onReceive,
    this.onAdjustExpiredProduct,
    this.onAdjustExpiredLot,
    this.onOpenStockCard,
    this.onOpenReceipt,
    this.onCompareSuppliers,
  });

  Widget? _buildLotBadge(StockLot lot) {
    if (lot.isExpired) {
      return const VBadge(
        label: 'Hết hạn',
        tone: VComponentTone.danger,
        showDot: true,
        hollowDot: true,
      );
    }
    if (lot.isNearExpiry) {
      return const VBadge(
        label: 'Cận hạn',
        tone: VComponentTone.warning,
        showDot: true,
      );
    }
    return null;
  }

  Widget _buildSummaryColumn(BuildContext context, List<StockLot> sortedLots) {
    final colors = context.vColors;
    final inds = detail.indicators;
    StockIndicator? issue;
    if (inds.contains(StockIndicator.out)) {
      issue = StockIndicator.out;
    } else if (inds.contains(StockIndicator.low)) {
      issue = StockIndicator.low;
    }

    final expiredLots = sortedLots.where((l) => l.isExpired).toList();
    final expiredQty = expiredLots.fold<num>(0, (sum, l) => sum + l.physical);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StockHeroCard(
          detail: detail,
          onEditThreshold: onEditThreshold,
        ),
        if (issue != null) ...[
          const SizedBox(height: VSpacing.space3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              VBanner(
                tone: issue == StockIndicator.out
                    ? VComponentTone.danger
                    : VComponentTone.warning,
                title: issue.label,
                description:
                    'Khả dụng ${formatStockQuantity(detail.available, detail.uom)}${detail.threshold != null ? ' · Ngưỡng ${formatStockQuantity(detail.threshold!, detail.uom)}.' : '.'}',
              ),
              if (detail.target != null &&
                  detail.target! > detail.available) ...[
                const SizedBox(height: VSpacing.space2),
                Text(
                  'Gợi ý nhập thêm ${formatStockQuantity(detail.target! - detail.available, detail.uom)} (mục tiêu ${formatStockQuantity(detail.target!, detail.uom)})',
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
              if (onReceive != null) ...[
                const SizedBox(height: VSpacing.space2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: VButton(
                    label: 'Nhận hàng',
                    variant: VButtonVariant.secondary,
                    onPressed: onReceive,
                  ),
                ),
              ],
            ],
          ),
        ],
        if (expiredLots.isNotEmpty) ...[
          const SizedBox(height: VSpacing.space3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              VBanner(
                tone: VComponentTone.danger,
                title: 'Có lô hết hạn',
                description:
                    'Lô ${expiredLots.map((l) => l.code).join(' · ')} · ${formatStockQuantity(expiredQty, detail.uom)} không đủ điều kiện bán.',
              ),
              if (onAdjustExpiredProduct != null) ...[
                const SizedBox(height: VSpacing.space2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: VButton(
                    label: 'Điều chỉnh lô hết hạn',
                    variant: VButtonVariant.secondary,
                    onPressed: onAdjustExpiredProduct,
                  ),
                ),
              ],
            ],
          ),
        ],
        if (detail.threshold == null) ...[
          const SizedBox(height: VSpacing.space2),
          Text(
            'Chưa cấu hình ngưỡng tồn; chưa thể xác định trạng thái tồn thấp/bình thường.',
            style: TextStyle(
              fontSize: 13,
              height: 20 / 13,
              color: context.vColors.textSecondary,
            ),
          ),
          if (detail.isOwner && onEditThreshold != null) ...[
            const SizedBox(height: VSpacing.space2),
            Align(
              alignment: Alignment.centerLeft,
              child: VButton(
                label: 'Đặt ngưỡng tồn',
                variant: VButtonVariant.secondary,
                onPressed: onEditThreshold,
              ),
            ),
          ],
        ],
        if (detail.cost != null) ...[
          const SizedBox(height: VSpacing.space3),
          StockCostBlock(
            cost: detail.cost!,
            uom: detail.uom,
            onShowVersions: detail.isOwner
                ? () => showCostVersionsSheet(
                      context,
                      productId: detail.productId,
                    )
                : null,
          ),
        ],
      ],
    );
  }

  Widget _buildMoreColumn(
    BuildContext context,
    List<StockLot> sortedLots,
    bool isWide,
  ) {
    final colors = context.vColors;

    void openLot(StockLot lot) {
      StockLotSheet.show(
        context: context,
        lot: lot,
        productName: detail.name,
        uom: detail.uom,
        onAdjustExpired: onAdjustExpiredLot == null
            ? null
            : () => onAdjustExpiredLot!(lot),
      );
    }

    Widget buildMobileLotRow(StockLot lot) {
      final expiryText = lot.expiry?.format() ?? 'Không có HSD';
      return VListRow(
        asCard: true,
        title: 'Lô ${lot.code}',
        subtitle:
            'HSD $expiryText · Tồn ${formatStockQuantity(lot.physical, detail.uom)}',
        trailing: _buildLotBadge(lot),
        type: VListRowType.navigation,
        onTap: () => openLot(lot),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (detail.isLotTracked) ...[
          VSection(
            title: 'Lô và hạn dùng',
            trailing: Text(
              '${sortedLots.length} lô',
              style: TextStyle(
                fontSize: 13,
                height: 20 / 13,
                color: context.vColors.textSecondary,
              ),
            ),
            child: isWide
                ? K7Table<StockLot>(
                    columns: [
                      K7Column(
                        label: 'Lô',
                        cell: (lot) => Text(
                          'Lô ${lot.code}',
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      K7Column(
                        label: 'HSD',
                        cell: (lot) => Text(
                          lot.expiry?.format() ?? 'Không có HSD',
                          style: TextStyle(
                            fontFamily: VTypography.monoFontFamily,
                            fontSize: 14,
                            height: 20 / 14,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      K7Column(
                        label: 'Tồn',
                        numeric: true,
                        cell: (lot) => Text(
                          formatStockQuantity(lot.physical, detail.uom),
                          style: TextStyle(
                            fontFamily: VTypography.monoFontFamily,
                            fontSize: 14,
                            height: 20 / 14,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      K7Column(
                        label: 'Tình trạng',
                        cell: (lot) =>
                            _buildLotBadge(lot) ?? const SizedBox.shrink(),
                      ),
                    ],
                    rows: sortedLots,
                    mobileRow: buildMobileLotRow,
                    onRowTap: openLot,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < sortedLots.length; i++) ...[
                        buildMobileLotRow(sortedLots[i]),
                        if (i < sortedLots.length - 1)
                          const SizedBox(height: VSpacing.space2),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: VSpacing.space3),
        ],
        if (onCompareSuppliers != null) ...[
          VListRow(
            asCard: true,
            leading: VIcons.coins,
            title: 'So sánh nhà cung cấp',
            subtitle: 'Giá gốc và ưu đãi theo từng nhà cung cấp',
            type: VListRowType.navigation,
            onTap: onCompareSuppliers,
          ),
          const SizedBox(height: VSpacing.space3),
        ],
        VListRow(
          asCard: true,
          leading: VIcons.history,
          title: 'Nguồn và thời điểm cập nhật',
          subtitle: 'Xem nguồn số liệu và lịch sử',
          type: VListRowType.navigation,
          onTap: () => StockProvenanceSheet.show(
            context: context,
            detail: detail,
            onOpenReceipt: onOpenReceipt,
            onOpenStockCard: onOpenStockCard,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = inventoryIsWide(context);
    final sortedLots = sortStockLots(detail.lots);

    if (isWide && !singleColumn) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: _buildSummaryColumn(context, sortedLots),
          ),
          const SizedBox(width: VSpacing.space6),
          Expanded(
            flex: 7,
            child: _buildMoreColumn(context, sortedLots, isWide),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSummaryColumn(context, sortedLots),
        SizedBox(height: singleColumn ? VSpacing.space4 : VSpacing.space3),
        _buildMoreColumn(context, sortedLots, isWide),
      ],
    );
  }
}
