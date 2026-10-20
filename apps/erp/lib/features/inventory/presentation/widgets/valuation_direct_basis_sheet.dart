import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/valuation_direct_basis_draft.dart';

class ValuationDirectBasisSheet extends StatefulWidget {
  const ValuationDirectBasisSheet({
    super.key,
    required this.productName,
    required this.uom,
  });

  final String productName;
  final String uom;

  static Future<ValuationDirectBasisDraft?> show(
    BuildContext context, {
    required String productName,
    required String uom,
  }) {
    return showVBottomSheet<ValuationDirectBasisDraft>(
      context: context,
      title: 'Thêm căn cứ giá',
      child: ValuationDirectBasisSheet(
        productName: productName,
        uom: uom,
      ),
    );
  }

  @override
  State<ValuationDirectBasisSheet> createState() =>
      _ValuationDirectBasisSheetState();
}

class _ValuationDirectBasisSheetState extends State<ValuationDirectBasisSheet> {
  final _priceController = TextEditingController();
  final _taxAmountController = TextEditingController(text: '0');
  final _sourceController = TextEditingController();
  final _referenceController = TextEditingController();
  final _reasonController = TextEditingController();

  ValuationTaxMode _taxMode = ValuationTaxMode.included;
  DateTime? _selectedDate;

  String? _priceError;
  String? _sourceError;
  String? _dateError;
  String? _reasonError;

  @override
  void dispose() {
    _priceController.dispose();
    _taxAmountController.dispose();
    _sourceController.dispose();
    _referenceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateError = null;
      });
    }
  }

  void _submit() {
    final rawPrice = double.tryParse(
          _priceController.text.replaceAll(',', '').replaceAll('.', '').trim(),
        ) ??
        0.0;
    final source = _sourceController.text.trim();
    final reason = _reasonController.text.trim();
    final rawTax = double.tryParse(
          _taxAmountController.text
              .replaceAll(',', '')
              .replaceAll('.', '')
              .trim(),
        ) ??
        0.0;

    var hasError = false;
    setState(() {
      if (rawPrice <= 0) {
        _priceError = 'Nhập đơn giá lớn hơn 0';
        hasError = true;
      } else {
        _priceError = null;
      }

      if (source.isEmpty) {
        _sourceError = 'Nhập nguồn căn cứ';
        hasError = true;
      } else {
        _sourceError = null;
      }

      if (_selectedDate == null) {
        _dateError = 'Chọn ngày căn cứ';
        hasError = true;
      } else {
        _dateError = null;
      }

      if (reason.isEmpty) {
        _reasonError = 'Nêu lý do xác lập trực tiếp';
        hasError = true;
      } else {
        _reasonError = null;
      }
    });

    if (hasError) return;

    final draft = ValuationDirectBasisDraft(
      unitPrice: rawPrice,
      taxMode: _taxMode,
      taxAmount: _taxMode == ValuationTaxMode.excluded ? rawTax : 0.0,
      source: source,
      date: _selectedDate,
      reference: _referenceController.text.trim().isEmpty
          ? null
          : _referenceController.text.trim(),
      reason: reason,
    );

    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.productName} · Nhập thông tin cần thiết để kế toán và người kiểm tra có thể truy vết căn cứ.',
            style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const VGap(VSpacing.space4),

          // Đơn giá mua
          VField(
            invalid: _priceError != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VFieldLabel('Đơn giá mua (VND/${widget.uom})', isRequired: true),
                const VGap(VSpacing.space1),
                VMoneyField(
                  controller: _priceController,
                  hintText: 'Nhập đơn giá',
                  onChanged: (_) {
                    if (_priceError != null) setState(() => _priceError = null);
                  },
                ),
                if (_priceError != null) ...[
                  const VGap(VSpacing.space1),
                  VFieldError(_priceError!),
                ],
              ],
            ),
          ),
          const VGap.cozy(),

          // Cách hiểu giá
          Text(
            'Cách hiểu giá',
            style: VTypography.labelDefault.copyWith(color: colors.textPrimary),
          ),
          const VGap(VSpacing.space1),
          VSegmentedControl(
            segments: const ['Đã gồm thuế', 'Chưa gồm thuế'],
            selectedIndex: _taxMode == ValuationTaxMode.included ? 0 : 1,
            onChanged: (index) {
              setState(() {
                _taxMode = index == 0
                    ? ValuationTaxMode.included
                    : ValuationTaxMode.excluded;
              });
            },
          ),
          const VGap.cozy(),

          // Thuế tính vào giá trị (nếu chưa gồm thuế)
          if (_taxMode == ValuationTaxMode.excluded) ...[
            VField(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VFieldLabel('Thuế tính vào giá trị (không thu hồi)'),
                  const VGap(VSpacing.space1),
                  VMoneyField(
                    controller: _taxAmountController,
                    hintText: '0',
                  ),
                  const VGap(VSpacing.space1),
                  const VFieldDescription(
                    'Nhập phần thuế không được khấu trừ nếu có.',
                  ),
                ],
              ),
            ),
            const VGap.cozy(),
          ],

          // Nguồn căn cứ
          VField(
            invalid: _sourceError != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VFieldLabel('Nguồn căn cứ', isRequired: true),
                const VGap(VSpacing.space1),
                VTextField(
                  controller: _sourceController,
                  hintText: 'Ví dụ: Xác nhận giá từ nhà cung cấp',
                  onChanged: (_) {
                    if (_sourceError != null) {
                      setState(() => _sourceError = null);
                    }
                  },
                ),
                if (_sourceError != null) ...[
                  const VGap(VSpacing.space1),
                  VFieldError(_sourceError!),
                ],
              ],
            ),
          ),
          const VGap.cozy(),

          // Ngày căn cứ
          VField(
            invalid: _dateError != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VFieldLabel('Ngày căn cứ', isRequired: true),
                const VGap(VSpacing.space1),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(VRadius.input),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.space3,
                      vertical: VSpacing.space2 + 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _dateError != null
                            ? colors.danger
                            : colors.borderDefault,
                      ),
                      borderRadius: BorderRadius.circular(VRadius.input),
                      color: colors.surface,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'Chọn ngày căn cứ (dd/mm/yyyy)'
                              : _formatDate(_selectedDate!),
                          style: VTypography.bodyDefault.copyWith(
                            color: _selectedDate == null
                                ? colors.textMuted
                                : colors.textPrimary,
                          ),
                        ),
                        const VIcon(
                          icon: VIcons.calendar,
                          iconSize: VIconSize.sm,
                          iconColor: VIconColor.muted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_dateError != null) ...[
                  const VGap(VSpacing.space1),
                  VFieldError(_dateError!),
                ],
              ],
            ),
          ),
          const VGap.cozy(),

          // Tham chiếu / bằng chứng
          VField(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VFieldLabel('Tham chiếu / bằng chứng'),
                const VGap(VSpacing.space1),
                VTextField(
                  controller: _referenceController,
                  hintText: 'Mã báo giá, email, ghi chú...',
                ),
              ],
            ),
          ),
          const VGap.cozy(),

          // Lý do xác lập trực tiếp
          VField(
            invalid: _reasonError != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VFieldLabel('Lý do xác lập trực tiếp', isRequired: true),
                const VGap(VSpacing.space1),
                VTextArea(
                  controller: _reasonController,
                  hintText: 'Nêu ngắn gọn lý do khi chưa có chứng từ mua có cấu trúc',
                  minLines: 3,
                  maxLines: 5,
                  onChanged: (_) {
                    if (_reasonError != null) {
                      setState(() => _reasonError = null);
                    }
                  },
                ),
                if (_reasonError != null) ...[
                  const VGap(VSpacing.space1),
                  VFieldError(_reasonError!),
                ],
              ],
            ),
          ),
          const VGap(VSpacing.space5),

          // CTA
          VButton(
            label: 'Lưu căn cứ',
            fullWidth: true,
            variant: VButtonVariant.primary,
            size: VButtonSize.large,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
