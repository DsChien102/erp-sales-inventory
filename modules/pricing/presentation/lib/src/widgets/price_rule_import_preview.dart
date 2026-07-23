import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import '../cubit/price_rule_import_cubit.dart';
import '../cubit/price_rule_import_state.dart';
import 'price_rule_import_issue_detail_sheet.dart';
import 'price_rule_import_shared.dart';

/// SG-04 — Preview dòng import trước khi xác nhận (khớp design Kiểm tra).
///
/// Header (mô tả + chip thống kê + tab) cố định; chỉ danh sách/bảng trong tab cuộn.
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VText(
                  widget.readOnly
                      ? 'Xem lại dữ liệu đã kiểm tra trước khi nhập.'
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
                Expanded(
                  child: _tab == PriceRuleImportPreviewTab.valid
                      ? _ValidRowsTable(rows: _filteredRows)
                      : _IssueRowsList(rows: _filteredRows),
                ),
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

  static const _columnFlex = [1.4, 1.2, 0.8, 0.9];

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const VEmptyState(
        icon: VIcons.check,
        title: 'Không có dòng hợp lệ',
        description: 'Không có dòng dữ liệu hợp lệ để hiển thị.',
      );
    }

    final colors = context.vColors;

    return VCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ValidTableHeader(colors: colors),
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 1,
                color: colors.borderDefault,
              ),
              itemBuilder: (context, index) {
                final row = rows[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: VSpacing.space3,
                    horizontal: VSpacing.space2,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _flexCell(
                        flex: _columnFlex[0],
                        child: _cell(
                          PriceRuleImportRowLabels.customer(row),
                        ),
                      ),
                      _flexCell(
                        flex: _columnFlex[1],
                        child: _cell(
                          PriceRuleImportRowLabels.product(row),
                        ),
                      ),
                      _flexCell(
                        flex: _columnFlex[2],
                        child: _cell(
                          '${PriceRuleImportRowLabels.unit(row)}\n'
                          '${PriceRuleImportRowLabels.unitKind(row)}',
                        ),
                      ),
                      _flexCell(
                        flex: _columnFlex[3],
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _cell(
                            PriceRuleImportRowLabels.price(row),
                            mono: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _flexCell({required double flex, required Widget child}) {
    return Expanded(
      flex: (flex * 10).round(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.space2),
        child: child,
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

class _ValidTableHeader extends StatelessWidget {
  const _ValidTableHeader({required this.colors});

  final VColorScheme colors;

  static const _titles = [
    ('Khách hàng', false),
    ('Sản phẩm', false),
    ('Đơn vị', false),
    ('Giá nhỏ', true),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.borderStrong, width: 1.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: VSpacing.space3,
          horizontal: VSpacing.space2,
        ),
        child: Row(
          children: [
            for (var i = 0; i < _titles.length; i++)
              Expanded(
                flex: (_ValidRowsTable._columnFlex[i] * 10).round(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.space2,
                  ),
                  child: VText(
                    _titles[i].$1.toUpperCase(),
                    variant: VTextVariant.caption,
                    color: colors.textSecondary,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    textAlign:
                        _titles[i].$2 ? TextAlign.right : TextAlign.left,
                  ),
                ),
              ),
          ],
        ),
      ),
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

    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, _) => const VGap.xs(),
      itemBuilder: (context, index) {
        final row = rows[index];
        return PriceRuleImportRowTile(
          row: row,
          onTap: () => showPriceRuleImportIssueDetailSheet(
            context: context,
            row: row,
          ),
        );
      },
    );
  }
}
