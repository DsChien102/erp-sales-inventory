import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/lot_date.dart';
import '../../data/models/receipt_lot_draft.dart';
import '../../logic/receipt_rules.dart';
import 'receipt_key_value_row.dart';

const _precisionLabels = ['Ngày/tháng/năm', 'Tháng/năm', 'Năm'];
const _precisions = [DatePrecision.day, DatePrecision.month, DatePrecision.year];
const _invalidDateMessage = 'Hạn dùng không đúng định dạng';

String _dateHint(DatePrecision p) => switch (p) {
      DatePrecision.day => 'dd/mm/yyyy',
      DatePrecision.month => 'mm/yyyy',
      DatePrecision.year => 'yyyy',
    };

class ReceiptLotEditorCard extends StatefulWidget {
  const ReceiptLotEditorCard({
    super.key,
    required this.lot,
    required this.index,
    required this.isLotTracked,
    required this.unitName,
    required this.onChanged,
    this.requiresExpiry = false,
    this.issues = const {},
    this.onDelete,
    this.readOnly = false,
  });

  final ReceiptLotDraft lot;
  final int index;
  final bool isLotTracked;
  final bool requiresExpiry;
  final String unitName;
  final ValueChanged<ReceiptLotDraft> onChanged;
  final Set<LotIssue> issues;
  final VoidCallback? onDelete;
  final bool readOnly;

  @override
  State<ReceiptLotEditorCard> createState() => _ReceiptLotEditorCardState();
}

class _ReceiptLotEditorCardState extends State<ReceiptLotEditorCard> {
  late final TextEditingController _lotCodeController =
      TextEditingController(text: widget.lot.lotCode);
  late final TextEditingController _expiryController =
      TextEditingController(text: widget.lot.expiryDate?.format() ?? '');
  late final TextEditingController _manufactureController =
      TextEditingController(text: widget.lot.manufactureDate?.format() ?? '');

  late DatePrecision _expiryPrecision =
      widget.lot.expiryDate?.precision ?? DatePrecision.day;
  late DatePrecision _manufacturePrecision =
      widget.lot.manufactureDate?.precision ?? DatePrecision.day;
  late bool _showManufacture = widget.lot.manufactureDate != null;

  @override
  void didUpdateWidget(covariant ReceiptLotEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lot.lotCode != _lotCodeController.text) {
      _lotCodeController.text = widget.lot.lotCode;
    }
  }

  @override
  void dispose() {
    _lotCodeController.dispose();
    _expiryController.dispose();
    _manufactureController.dispose();
    super.dispose();
  }

  void _onExpiryChanged() {
    final parsed = LotDate.tryParse(_expiryController.text, _expiryPrecision);
    widget.onChanged(
      parsed != null
          ? widget.lot.copyWith(expiryDate: parsed)
          : widget.lot.copyWith(clearExpiryDate: true),
    );
  }

  void _onManufactureChanged() {
    final parsed =
        LotDate.tryParse(_manufactureController.text, _manufacturePrecision);
    widget.onChanged(
      parsed != null
          ? widget.lot.copyWith(manufactureDate: parsed)
          : widget.lot.copyWith(clearManufactureDate: true),
    );
  }

  LotIssue? _firstIssue(Set<LotIssue> wanted) {
    for (final issue in widget.issues) {
      if (wanted.contains(issue)) return issue;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final lot = widget.lot;
    final unit = widget.unitName;

    if (widget.readOnly) return _buildReadOnly(context);

    final lotCodeIssue = _firstIssue(
      {LotIssue.missingLotCode, LotIssue.duplicateLotCode},
    );
    final expiryText = _expiryController.text.trim();
    final expiryFormatInvalid = expiryText.isNotEmpty && lot.expiryDate == null;
    final expiryIssue = expiryFormatInvalid
        ? null
        : _firstIssue({
            LotIssue.missingExpiry,
            LotIssue.expiryNotAfterManufacture,
            LotIssue.lotConflict,
          });
    final expiryError = expiryFormatInvalid
        ? _invalidDateMessage
        : (expiryIssue != null ? lotIssueMessage(expiryIssue) : null);
    final qtyIssue = _firstIssue(
      {LotIssue.emptyQuantity, LotIssue.negativeQuantity},
    );

    return VCard(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isLotTracked) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText(
                          lot.lotCode.trim().isEmpty ? 'Lô mới' : lot.lotCode,
                          style: VTypography.labelDefault.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const VGap(VSpacing.space1),
                        VText(
                          '${formatQuantity(lot.totalReceived)} $unit · ${formatQuantity(lot.accepted)} đạt',
                          style: VTypography.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onDelete != null)
                    VButton.icon(
                      icon: VIcons.delete,
                      semanticLabel: 'Xoá lô',
                      variant: VButtonVariant.tertiary,
                      size: VButtonSize.small,
                      onPressed: widget.onDelete,
                    ),
                ],
              ),
              const VGap.cozy(),
              VField(
                invalid: lotCodeIssue != null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VFieldLabel('Mã lô', isRequired: true),
                    const VGap(VSpacing.space1),
                    VTextField(
                      controller: _lotCodeController,
                      hintText: 'Nhập mã trên bao bì',
                      onChanged: (val) {
                        widget.onChanged(lot.copyWith(lotCode: val));
                      },
                    ),
                    if (lotCodeIssue != null) ...[
                      const VGap(VSpacing.space1),
                      VFieldError(lotIssueMessage(lotCodeIssue)),
                    ],
                  ],
                ),
              ),
              const VGap.cozy(),
              VField(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VFieldLabel('Cách ghi hạn dùng'),
                    const VGap(VSpacing.space1),
                    VSegmentedControl(
                      segments: _precisionLabels,
                      selectedIndex: _precisions.indexOf(_expiryPrecision),
                      onChanged: (i) {
                        setState(() => _expiryPrecision = _precisions[i]);
                        _onExpiryChanged();
                      },
                    ),
                  ],
                ),
              ),
              const VGap.cozy(),
              VField(
                invalid: expiryError != null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VFieldLabel('Hạn dùng', isRequired: widget.requiresExpiry),
                    const VGap(VSpacing.space1),
                    VTextField(
                      controller: _expiryController,
                      hintText: _dateHint(_expiryPrecision),
                      keyboardType: TextInputType.datetime,
                      onChanged: (_) {
                        setState(() {});
                        _onExpiryChanged();
                      },
                    ),
                    const VGap(VSpacing.space1),
                    if (expiryError != null)
                      VFieldError(expiryError)
                    else
                      const VFieldDescription('Nhập đúng định dạng trên bao bì.'),
                  ],
                ),
              ),
              const VGap(VSpacing.space2),
              if (!_showManufacture)
                Align(
                  alignment: Alignment.centerLeft,
                  child: VButton(
                    label: 'Thêm ngày sản xuất',
                    variant: VButtonVariant.link,
                    onPressed: () => setState(() => _showManufacture = true),
                  ),
                )
              else ...[
                const VGap(VSpacing.space1),
                VField(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Cách ghi ngày sản xuất'),
                      const VGap(VSpacing.space1),
                      VSegmentedControl(
                        segments: _precisionLabels,
                        selectedIndex:
                            _precisions.indexOf(_manufacturePrecision),
                        onChanged: (i) {
                          setState(
                            () => _manufacturePrecision = _precisions[i],
                          );
                          _onManufactureChanged();
                        },
                      ),
                    ],
                  ),
                ),
                const VGap.cozy(),
                VField(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Ngày sản xuất'),
                      const VGap(VSpacing.space1),
                      VTextField(
                        controller: _manufactureController,
                        hintText: _dateHint(_manufacturePrecision),
                        keyboardType: TextInputType.datetime,
                        onChanged: (_) {
                          setState(() {});
                          _onManufactureChanged();
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const VGap(VSpacing.space4),
            ],
            VField(
              invalid: qtyIssue != null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VText(
                    'Phân loại số lượng',
                    style: VTypography.labelDefault.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const VGap(VSpacing.space2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _qtyField(
                          'Đạt',
                          lot.accepted,
                          (v) => widget.onChanged(lot.copyWith(accepted: v)),
                        ),
                      ),
                      const VGap(VSpacing.space2, axis: Axis.horizontal),
                      Expanded(
                        child: _qtyField(
                          'Cách ly',
                          lot.quarantine,
                          (v) => widget.onChanged(lot.copyWith(quarantine: v)),
                        ),
                      ),
                    ],
                  ),
                  const VGap(VSpacing.space2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _qtyField(
                          'Hỏng',
                          lot.damaged,
                          (v) => widget.onChanged(lot.copyWith(damaged: v)),
                        ),
                      ),
                      const VGap(VSpacing.space2, axis: Axis.horizontal),
                      Expanded(
                        child: _qtyField(
                          'Từ chối',
                          lot.rejected,
                          (v) => widget.onChanged(lot.copyWith(rejected: v)),
                          helper: lot.rejected > 0 ? 'Không vào tồn' : null,
                        ),
                      ),
                    ],
                  ),
                  if (qtyIssue != null) ...[
                    const VGap(VSpacing.space1),
                    VFieldError(lotIssueMessage(qtyIssue)),
                  ],
                ],
              ),
            ),
            const VGap.cozy(),
            ReceiptKeyValueRow(
              label: 'Tổng kiểm nhận',
              value: '${formatQuantity(lot.totalReceived)} $unit',
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyField(
    String label,
    double value,
    ValueChanged<double> onChanged, {
    String? helper,
  }) {
    final colors = context.vColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(
          label,
          style: VTypography.caption.copyWith(fontWeight: FontWeight.w500),
        ),
        const VGap(VSpacing.space1),
        VNumberField(
          value: value,
          allowNegative: false,
          allowDecimal: false,
          min: 0,
          textAlign: TextAlign.center,
          onChanged: (v) => onChanged((v ?? 0).toDouble()),
        ),
        if (helper != null) ...[
          const VGap(VSpacing.space1),
          VText(
            helper,
            style: VTypography.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildReadOnly(BuildContext context) {
    final colors = context.vColors;
    final lot = widget.lot;
    final unit = widget.unitName;

    return VCard(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isLotTracked) ...[
              VText(
                lot.lotCode.trim().isEmpty ? 'Lô mới' : lot.lotCode,
                style: VTypography.labelDefault.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const VGap(VSpacing.space2),
              ReceiptKeyValueRow(label: 'Mã lô', value: lot.lotCode),
              if (lot.expiryDate != null)
                ReceiptKeyValueRow(
                  label: 'Hạn dùng',
                  value: lot.expiryDate!.format(),
                ),
              if (lot.manufactureDate != null)
                ReceiptKeyValueRow(
                  label: 'Ngày sản xuất',
                  value: lot.manufactureDate!.format(),
                ),
            ] else
              VText(
                'Phân loại số lượng',
                style: VTypography.labelDefault.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ReceiptKeyValueRow(
              label: 'Đạt',
              value: '${formatQuantity(lot.accepted)} $unit',
            ),
            ReceiptKeyValueRow(
              label: 'Cách ly',
              value: '${formatQuantity(lot.quarantine)} $unit',
            ),
            ReceiptKeyValueRow(
              label: 'Hỏng',
              value: '${formatQuantity(lot.damaged)} $unit',
            ),
            ReceiptKeyValueRow(
              label: 'Từ chối (không vào tồn)',
              value: '${formatQuantity(lot.rejected)} $unit',
            ),
            const VDivider(),
            ReceiptKeyValueRow(
              label: 'Tổng kiểm nhận',
              value: '${formatQuantity(lot.totalReceived)} $unit',
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}
