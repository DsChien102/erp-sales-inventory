import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/logic/costing/costing_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

String formatUnitCostOrTemp(num? unitCost, String uom) {
  if (unitCost == null) return 'Giá tạm';
  return '${moneyWithSpace(unitCost.round())}/$uom';
}

/// 2 thẻ chỉ số đầu trang 074: Giá trị tồn cuối · Giá vốn xuất.
class CostMetricCards extends StatelessWidget {
  const CostMetricCards({super.key, required this.totals});

  final CostTotals totals;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CostMetricCard(
        label: 'Giá trị tồn cuối',
        value: moneyWithSpace(totals.closingValue),
      ),
      _CostMetricCard(
        label: 'Giá vốn xuất',
        value: moneyWithSpace(totals.cogsValue),
      ),
    ];

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: VSpacing.space3),
        Expanded(child: cards[1]),
      ],
    );
  }
}

class _CostMetricCard extends StatelessWidget {
  const _CostMetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.r12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          VText(
            label,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          const SizedBox(height: VSpacing.space1),
          Text(
            value,
            style: VTypography.monoNumeric.copyWith(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Khối ③: Thay đổi sẽ ghi khi công bố.
class CostWritesBlock extends StatelessWidget {
  const CostWritesBlock({super.key, required this.totals});

  final CostTotals totals;

  @override
  Widget build(BuildContext context) {
    return VSection(
      title: 'Thay đổi sẽ ghi khi công bố',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          VText(
            'Chỉ phần chênh lệch dưới đây được ghi; chứng từ lịch sử không bị sửa.',
            variant: VTextVariant.bodySmall,
            color: context.vColors.textSecondary,
          ),
          const SizedBox(height: VSpacing.space3),
          VKeyValueGroup(
            rows: [
              VKeyValueRow(
                label: 'Điều chỉnh giá vốn xuất',
                value: signedMoney(totals.cogsAdjust),
                mono: true,
              ),
              VKeyValueRow(
                label: 'Điều chỉnh giá trị tồn',
                value: signedMoney(totals.valueAdjust),
                mono: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Khối ⑤: Phương pháp đang áp dụng + nút đối chiếu tuỳ chọn.
class CostMethodBlock extends StatelessWidget {
  const CostMethodBlock({
    super.key,
    required this.method,
    this.altMethod,
    this.onCompare,
  });

  final CostMethod method;
  final CostMethod? altMethod;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final (label, sentence) = methodCopy(method);
    final compareLabel =
        altMethod != null ? 'Xem đối chiếu theo ${methodCopy(altMethod!).$1}' : null;

    return VSection(
      title: 'Phương pháp',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              style: VTypography.bodyDefault.copyWith(
                fontSize: 14,
                height: 22 / 14,
                color: colors.textPrimary,
              ),
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ' — $sentence'),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.space2),
          VText(
            'Theo chính sách của cửa hàng; không đổi theo lần tính.',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          if (compareLabel != null && onCompare != null) ...[
            const SizedBox(height: VSpacing.space3),
            Align(
              alignment: Alignment.centerLeft,
              child: VButton(
                label: compareLabel,
                variant: VButtonVariant.secondary,
                onPressed: onCompare,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cột phụ web: Tóm tắt 4 dòng.
class CostSummaryGroup extends StatelessWidget {
  const CostSummaryGroup({super.key, required this.run});

  final CostRunView run;

  @override
  Widget build(BuildContext context) {
    return VKeyValueGroup(
      title: 'Tóm tắt',
      rows: [
        VKeyValueRow(
          label: 'Kỳ',
          value: periodLabel(run.periodMonth),
          mono: true,
        ),
        const VKeyValueRow(
          label: 'Phạm vi',
          value: 'Toàn bộ sản phẩm',
        ),
        VKeyValueRow(
          label: 'Thời điểm chốt',
          value: formatDateTimeDdMmYyyyHm(run.cutOffAt),
          mono: true,
        ),
        VKeyValueRow(
          label: 'Phương pháp',
          value: methodCopy(run.method).$1,
        ),
      ],
    );
  }
}

/// Danh sách việc chặn khi run `BLOCKED`.
class CostBlockerList extends StatelessWidget {
  const CostBlockerList({
    super.key,
    required this.blockers,
    required this.onAction,
  });

  final List<CostBlocker> blockers;
  final void Function(CostBlocker blocker, BlockerView view) onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.r12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < blockers.length; i++) ...[
            _CostBlockerRow(
              blocker: blockers[i],
              view: blockerView(blockers[i]),
              onAction: onAction,
            ),
            if (i < blockers.length - 1)
              Divider(height: 1, thickness: 1, color: colors.borderDefault),
          ],
        ],
      ),
    );
  }
}

class _CostBlockerRow extends StatelessWidget {
  const _CostBlockerRow({
    required this.blocker,
    required this.view,
    required this.onAction,
  });

  final CostBlocker blocker;
  final BlockerView view;
  final void Function(CostBlocker blocker, BlockerView view) onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isWide = inventoryIsWide(context);
    final hasAction =
        view.actionLabel != null && view.action != CostBlockerAction.none;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          view.title,
          style: VTypography.bodyDefault.copyWith(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        if (view.detail != null) ...[
          const SizedBox(height: 2),
          Text(
            view.detail!,
            style: VTypography.bodySmall.copyWith(
              fontSize: 13,
              height: 20 / 13,
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );

    final actionButton = hasAction
        ? ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: VButton(
              label: view.actionLabel!,
              variant: VButtonVariant.secondary,
              onPressed: () => onAction(blocker, view),
            ),
          )
        : null;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? VSpacing.space4 : VSpacing.space3,
        vertical: VSpacing.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: VIcon(
              icon: VIcons.warning,
              size: 20,
              color: colors.warning,
            ),
          ),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: isWide
                ? copy
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      copy,
                      if (actionButton != null) ...[
                        const SizedBox(height: VSpacing.space2),
                        actionButton,
                      ],
                    ],
                  ),
          ),
          if (isWide && actionButton != null) ...[
            const SizedBox(width: VSpacing.space3),
            actionButton,
          ],
        ],
      ),
    );
  }
}

/// Dòng sản phẩm dùng chung ở mobile (3 dòng đầu) và sheet "Theo sản phẩm".
class CostProductMobileRow extends StatelessWidget {
  const CostProductMobileRow({super.key, required this.line});

  final CostRunLineView line;

  @override
  Widget build(BuildContext context) {
    final oldText = formatUnitCostOrTemp(line.oldOfficialUnitCost, line.uom);
    final subtitle = line.changed && line.newUnitCost != null
        ? '$oldText → ${moneyWithSpace(line.newUnitCost!.round())}/${line.uom}'
        : 'Giữ $oldText';
    final trailing = line.lineAdjust != 0
        ? Text(
            signedMoney(line.lineAdjust),
            style: VTypography.monoNumeric.copyWith(
              fontSize: 13,
              height: 20 / 13,
              fontWeight: FontWeight.w600,
              color: context.vColors.textPrimary,
            ),
          )
        : const VBadge(label: 'Không đổi', tone: VComponentTone.neutral);

    return VListRow(
      title: line.name,
      subtitle: subtitle,
      trailing: trailing,
      onTap: null,
    );
  }
}

/// Khối ④: Theo sản phẩm + nút "Xem chi tiết tính".
class CostProductsBlock extends StatelessWidget {
  const CostProductsBlock({
    super.key,
    required this.lines,
    required this.onViewAllProducts,
    required this.onViewDetail,
  });

  final List<CostRunLineView> lines;
  final VoidCallback onViewAllProducts;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    final isWide = inventoryIsWide(context);
    final colors = context.vColors;

    final mobileTop = topChanged(lines, 3);
    final mobileLines =
        mobileTop.isNotEmpty ? mobileTop : lines.take(3).toList(growable: false);

    return VSection(
      title: 'Theo sản phẩm',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWide)
            K7Table<CostRunLineView>(
              columns: [
                K7Column<CostRunLineView>(
                  label: 'Sản phẩm',
                  cell: (line) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        line.name,
                        style: VTypography.bodyDefault.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        line.code,
                        style: VTypography.bodySmall.copyWith(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                K7Column<CostRunLineView>(
                  label: 'Giá vốn cũ',
                  numeric: true,
                  cell: (line) => Text(
                    formatUnitCostOrTemp(line.oldOfficialUnitCost, line.uom),
                    style: VTypography.monoNumeric.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                K7Column<CostRunLineView>(
                  label: 'Giá vốn mới',
                  numeric: true,
                  cell: (line) => Text(
                    line.changed && line.newUnitCost != null
                        ? '${moneyWithSpace(line.newUnitCost!.round())}/${line.uom}'
                        : '—',
                    style: VTypography.monoNumeric.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                K7Column<CostRunLineView>(
                  label: 'Chênh lệch',
                  numeric: true,
                  cell: (line) => line.lineAdjust != 0
                      ? Text(
                          signedMoney(line.lineAdjust),
                          style: VTypography.monoNumeric.copyWith(
                            color: colors.textPrimary,
                          ),
                        )
                      : const VBadge(
                          label: 'Không đổi',
                          tone: VComponentTone.neutral,
                        ),
                ),
              ],
              rows: lines,
              mobileRow: (line) => CostProductMobileRow(line: line),
            )
          else ...[
            for (var i = 0; i < mobileLines.length; i++) ...[
              CostProductMobileRow(line: mobileLines[i]),
              if (i < mobileLines.length - 1)
                Divider(height: 1, thickness: 1, color: colors.borderDefault),
            ],
            if (lines.isNotEmpty) ...[
              const SizedBox(height: VSpacing.space3),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: VButton(
                  label: 'Xem ${lines.length} sản phẩm',
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: onViewAllProducts,
                ),
              ),
            ],
          ],
          const SizedBox(height: VSpacing.space3),
          Align(
            alignment: isWide ? Alignment.centerLeft : Alignment.center,
            child: VButton(
              label: 'Xem chi tiết tính',
              variant: VButtonVariant.secondary,
              fullWidth: !isWide,
              onPressed: onViewDetail,
            ),
          ),
        ],
      ),
    );
  }
}
