import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import '../cubit/price_rule_import_cubit.dart';
import '../cubit/price_rule_import_state.dart';
import 'price_rule_import_issue_detail_sheet.dart';
import 'price_rule_import_shared.dart';

/// SG-04 — Preview dòng import trước khi xác nhận (khớp design Kiểm tra).
class PriceRuleImportPreviewView extends StatefulWidget {
  const PriceRuleImportPreviewView({
    super.key,
    required this.cubit,
    required this.importDetail,
    required this.rows,
    this.onBack,
    this.readOnly = false,
    this.initialTab = PriceRuleImportPreviewTab.valid,
  });

  final PriceRuleImportCubit cubit;
  final CustomerPriceRuleImportDetailDto importDetail;
  final List<CustomerPriceRuleImportRowPreviewDto> rows;
  final VoidCallback? onBack;
  final bool readOnly;
  final PriceRuleImportPreviewTab initialTab;

  @override
  State<PriceRuleImportPreviewView> createState() =>
      _PriceRuleImportPreviewViewState();
}

class _PriceRuleImportPreviewViewState
    extends State<PriceRuleImportPreviewView> {
  late PriceRuleImportPreviewTab _tab = widget.initialTab;

  CustomerPriceRuleImportDto get _batch => widget.importDetail.batch;

  List<CustomerPriceRuleImportRowPreviewDto> get _filteredRows {
    final status = switch (_tab) {
      PriceRuleImportPreviewTab.valid => CustomerPriceRuleImportRowStatus.valid,
      PriceRuleImportPreviewTab.warning =>
        CustomerPriceRuleImportRowStatus.warning,
      PriceRuleImportPreviewTab.error => CustomerPriceRuleImportRowStatus.error,
    };
    return widget.rows.where((r) => r.status == status).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final batch = _batch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: VPagePadding(
            child: ListView(
              children: [
                VText(
                  widget.readOnly
                      ? 'Xem lại dữ liệu đã kiểm tra trước khi import.'
                      : 'Hệ thống đã kiểm tra file. Vui lòng xem kết quả.',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                const VGap.md(),
                Row(
                  children: [
                    PriceRuleImportStatChip(
                      label: 'Tổng dòng',
                      value: batch.totalRows,
                      color: colors.textPrimary,
                    ),
                    const VGap.horizontalSm(),
                    PriceRuleImportStatChip(
                      label: 'Hợp lệ',
                      value: batch.validRows,
                      color: colors.success,
                    ),
                    const VGap.horizontalSm(),
                    PriceRuleImportStatChip(
                      label: 'Cảnh báo',
                      value: batch.warningRows,
                      color: colors.warning,
                    ),
                    const VGap.horizontalSm(),
                    PriceRuleImportStatChip(
                      label: 'Lỗi',
                      value: batch.errorRows,
                      color: colors.danger,
                    ),
                  ],
                ),
                const VGap.md(),
                VTabs(
                  tabs: [
                    'Dữ liệu hợp lệ (${batch.validRows})',
                    'Cảnh báo (${batch.warningRows})',
                    'Lỗi (${batch.errorRows})',
                  ],
                  selectedIndex: _tab.index,
                  isScrollable: true,
                  onTabSelected: (i) => setState(
                    () => _tab = PriceRuleImportPreviewTab.values[i],
                  ),
                ),
                const VGap.md(),
                if (_tab == PriceRuleImportPreviewTab.valid)
                  _ValidRowsTable(rows: _filteredRows)
                else
                  _IssueRowsList(rows: _filteredRows),
                const VGap.lg(),
                _QuickCheckSection(rows: widget.rows),
              ],
            ),
          ),
        ),
        VPagePadding(
          applyBottomSafeArea: true,
          vertical: VSpacing.space2,
          child: Row(
            children: [
              Expanded(
                child: VButton(
                  label: widget.readOnly ? 'Quay lại kết quả' : 'Quay lại',
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: widget.onBack ??
                      (widget.readOnly
                          ? widget.cubit.backToResult
                          : widget.cubit.backToChooseFile),
                ),
              ),
              if (!widget.readOnly) ...[
                const VGap.horizontalMd(),
                Expanded(
                  child: VButton(
                    label: 'Tiếp tục',
                    variant: VButtonVariant.primary,
                    fullWidth: true,
                    onPressed: batch.validRows + batch.warningRows > 0
                        ? widget.cubit.proceedToConfirm
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ValidRowsTable extends StatelessWidget {
  const _ValidRowsTable({required this.rows});

  final List<CustomerPriceRuleImportRowPreviewDto> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const VEmptyState(
        icon: VIcons.check,
        title: 'Không có dòng hợp lệ',
        description: 'Không có dòng dữ liệu hợp lệ để hiển thị.',
      );
    }

    return VCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width -
                    (VPagePadding.horizontalForWidth(
                          MediaQuery.sizeOf(context).width,
                        ) *
                        2);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minWidth),
              child: VTable(
                headers: const [
                  VTableHeader(title: 'Khách hàng'),
                  VTableHeader(title: 'Sản phẩm'),
                  VTableHeader(title: 'Đơn vị'),
                  VTableHeader(title: 'Giá nhỏ', isNumeric: true),
                ],
                columnWidths: const {
                  0: FlexColumnWidth(1.4),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(0.8),
                  3: FlexColumnWidth(0.9),
                },
                rows: [
                  for (final row in rows)
                    [
                      _cell(PriceRuleImportRowLabels.customer(row)),
                      _cell(PriceRuleImportRowLabels.product(row)),
                      _cell(
                        '${PriceRuleImportRowLabels.unit(row)}\n'
                        '${PriceRuleImportRowLabels.unitKind(row)}',
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _cell(
                          PriceRuleImportRowLabels.price(row),
                          mono: true,
                        ),
                      ),
                    ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _cell(String text, {bool mono = false}) {
    return VText(
      text,
      variant: mono ? VTextVariant.monoNumeric : VTextVariant.bodySmall,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _IssueRowsList extends StatelessWidget {
  const _IssueRowsList({required this.rows});

  final List<CustomerPriceRuleImportRowPreviewDto> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const VEmptyState(
        icon: VIcons.inbox,
        title: 'Không có dòng',
        description: 'Không có dòng thuộc nhóm này.',
      );
    }

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const VGap.xs(),
          PriceRuleImportRowTile(
            row: rows[i],
            onTap: () => showPriceRuleImportIssueDetailSheet(
              context: context,
              row: rows[i],
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickCheckSection extends StatelessWidget {
  const _QuickCheckSection({required this.rows});

  final List<CustomerPriceRuleImportRowPreviewDto> rows;

  @override
  Widget build(BuildContext context) {
    final belowZero = rows
        .where(
          (r) =>
              r.errorCodes.contains('INVALID_PRICE') ||
              (r.normalizedPriceMinor != null && r.normalizedPriceMinor! <= 0),
        )
        .length;
    final missingRequired = rows
        .where(
          (r) =>
              r.errorCodes.contains('REFERENCE_INVALID') ||
              ((r.customerId == null || r.customerId!.trim().isEmpty) ||
                  (r.productId == null || r.productId!.trim().isEmpty) ||
                  (r.productUnitId == null ||
                      r.productUnitId!.trim().isEmpty) ||
                  (r.price == null || r.price!.trim().isEmpty)),
        )
        .length;
    final duplicateInFile = _duplicateInFileCount(rows);

    return VSection(
      title: 'Kiểm tra nhanh',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PriceRuleImportBullet('Giá nhỏ dưới 0: $belowZero dòng'),
          PriceRuleImportBullet('Trùng rule trong file: $duplicateInFile dòng'),
          PriceRuleImportBullet(
            'Thiếu thông tin bắt buộc: $missingRequired dòng',
          ),
        ],
      ),
    );
  }

  static int _duplicateInFileCount(
    List<CustomerPriceRuleImportRowPreviewDto> rows,
  ) {
    final counts = <String, int>{};
    for (final row in rows) {
      final key =
          '${row.customerId ?? ''}|${row.productId ?? ''}|'
          '${row.productUnitId ?? ''}';
      if (key == '||') continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts.values.fold<int>(0, (sum, c) => c > 1 ? sum + c : sum);
  }
}
