import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../cubit/price_rule_form_cubit.dart';
import '../cubit/price_rule_form_state.dart';
import 'price_rule_form_edit_header.dart';
import 'price_rule_form_readiness_summary.dart';
import 'price_rule_price_field.dart';
import 'price_rule_warning_banner.dart';

typedef PriceRulePickResult = Map<String, String>;
typedef PriceRulePickCallback = Future<PriceRulePickResult?> Function();

/// Form tạo/sửa giá riêng — SG-03 D-02 → D-09.
class PriceRuleFormBody extends StatefulWidget {
  const PriceRuleFormBody({
    super.key,
    required this.cubit,
    required this.form,
    required this.priceController,
    required this.noteController,
    required this.isEdit,
    required this.onPriceChanged,
    this.onPickCustomer,
    this.onPickProduct,
    this.onPickUnit,
    this.onViewConflictingRule,
    this.lastUpdatedAt,
    this.lastUpdatedBy,
  });

  final PriceRuleFormCubit cubit;
  final PriceRuleFormEditing form;
  final TextEditingController priceController;
  final TextEditingController noteController;
  final bool isEdit;
  final ValueChanged<int?> onPriceChanged;
  final PriceRulePickCallback? onPickCustomer;
  final PriceRulePickCallback? onPickProduct;
  final PriceRulePickCallback? onPickUnit;
  final ValueChanged<String>? onViewConflictingRule;
  final DateTime? lastUpdatedAt;
  final String? lastUpdatedBy;

  @override
  State<PriceRuleFormBody> createState() => _PriceRuleFormBodyState();
}

class _PriceRuleFormBodyState extends State<PriceRuleFormBody> {
  late final TextEditingController _customerController;
  late final TextEditingController _productController;
  late final TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController(
      text: widget.form.customerName ?? '',
    );
    _productController = TextEditingController(
      text: widget.form.productName ?? '',
    );
    _unitController = TextEditingController(
      text: widget.form.productUnitName ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant PriceRuleFormBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(_customerController, widget.form.customerName);
    _sync(_productController, widget.form.productName);
    _sync(_unitController, widget.form.productUnitName);
  }

  void _sync(TextEditingController controller, String? value) {
    final next = value ?? '';
    if (controller.text != next) {
      controller.text = next;
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _productController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    final result = await widget.onPickCustomer?.call();
    if (result != null) {
      widget.cubit.selectCustomer(
        customerId: result['id']!,
        customerName: result['name']!,
        customerRoleLabel: result['role'],
      );
    }
  }

  Future<void> _pickProduct() async {
    final result = await widget.onPickProduct?.call();
    if (result != null) {
      final listDong = int.tryParse(result['listPriceDong'] ?? '');
      final floorDong = int.tryParse(result['floorPriceDong'] ?? '');
      widget.cubit.selectProduct(
        productId: result['id']!,
        productName: result['name']!,
        listPriceMinor: listDong,
        floorPriceMinor: floorDong,
      );
    }
  }

  Future<void> _pickUnit() async {
    final result = await widget.onPickUnit?.call();
    if (result != null) {
      final listDong = int.tryParse(result['listPriceDong'] ?? '');
      final floorDong = int.tryParse(result['floorPriceDong'] ?? '');
      widget.cubit.selectProductUnit(
        productUnitId: result['id']!,
        productUnitName: result['name']!,
        listPriceMinor: listDong,
        floorPriceMinor: floorDong,
        floorPriceHidden: floorDong == null,
      );
    }
  }

  Future<void> _pickEffectiveTo() async {
    final form = widget.form;
    final action = await showVBottomSheet<String>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.space4,
          VSpacing.space2,
          VSpacing.space4,
          VSpacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              'Đến ngày',
              variant: VTextVariant.headingH4,
              textAlign: TextAlign.center,
            ),
            const VGap.md(),
            VButton(
              label: 'Chọn ngày cụ thể',
              variant: VButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop('pick'),
            ),
            const VGap.sm(),
            VButton(
              label: 'Không giới hạn',
              variant: VButtonVariant.primary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop('clear'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'clear') {
      widget.cubit.clearEffectiveTo();
      return;
    }
    if (action == 'pick') {
      final today = _calendarDate(DateTime.now());
      final from = form.effectiveFrom == null
          ? today
          : _calendarDate(form.effectiveFrom!);
      final firstDate = from.isBefore(today) ? today : from;
      final preferred = form.effectiveTo == null
          ? firstDate
          : _calendarDate(form.effectiveTo!);
      final initialDate =
          preferred.isBefore(firstDate) ? firstDate : preferred;
      final date = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: DateTime(2100),
      );
      if (date != null) {
        widget.cubit.updateDates(effectiveTo: _calendarDate(date));
      }
    }
  }

  /// Calendar date as UTC midnight — matches domain/RPC date-only convention.
  /// Using local midnight here breaks same-day from/to when one side is UTC
  /// (e.g. loaded from API) and the other is picked in a +UTC offset TZ.
  static DateTime _calendarDate(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    final unitEnabled = form.productId != null && !widget.isEdit;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FormWarnings(
            form: form,
            onViewConflictingRule: widget.onViewConflictingRule,
          ),

          if (widget.isEdit) ...[
            VSection(
              title: 'Thông tin áp dụng',
              child: PriceRuleFormIdentityCard(
                customerName: form.customerName ?? '—',
                customerId: form.customerId ?? '—',
                productName: form.productName ?? '—',
                productUnitName: form.productUnitName ?? '—',
              ),
            ),
            const VGap.lg(),
          ] else
            VSection(
              title: 'Thông tin áp dụng',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PickerField(
                    label: 'Khách hàng',
                    isRequired: true,
                    controller: _customerController,
                    hintText: 'Tìm và chọn khách hàng...',
                    onTap: widget.onPickCustomer == null ? null : _pickCustomer,
                  ),
                  const VGap.md(),
                  _PickerField(
                    label: 'Sản phẩm',
                    isRequired: true,
                    controller: _productController,
                    hintText: 'Tìm và chọn sản phẩm...',
                    onTap: widget.onPickProduct == null ? null : _pickProduct,
                  ),
                  const VGap.md(),
                  _PickerField(
                    label: 'Đơn vị bán',
                    isRequired: true,
                    controller: _unitController,
                    hintText: form.productId == null
                        ? 'Chọn sản phẩm trước'
                        : 'Chọn đơn vị bán...',
                    enabled: unitEnabled,
                    onTap: !unitEnabled || widget.onPickUnit == null
                        ? null
                        : _pickUnit,
                  ),
                ],
              ),
            ),
          if (!widget.isEdit) const VGap.lg(),

          VSection(
            title: 'Mức giá áp dụng',
            child: PriceRulePriceField(
              controller: widget.priceController,
              onChanged: widget.onPriceChanged,
            ),
          ),

          if (form.showReadinessSummary) ...[
            const VGap.lg(),
            PriceRuleFormReadinessSummary(form: form),
          ],

          const VGap.lg(),

          VSection(
            title: 'Thời gian hiệu lực',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VDatePicker(
                  label: 'Từ ngày',
                  value: form.effectiveFrom,
                  required: true,
                  firstDate: _calendarDate(DateTime.now()),
                  lastDate: DateTime(2100),
                  onChanged: (date) {
                    widget.cubit.updateDates(effectiveFrom: _calendarDate(date));
                  },
                ),
                const VGap.md(),
                VDatePicker(
                  label: 'Đến ngày',
                  value: form.effectiveTo,
                  hintText: 'Không giới hạn',
                  onTap: _pickEffectiveTo,
                ),
              ],
            ),
          ),
          const VGap.md(),

          VTextFormField(
            key: const Key('input_price_rule_note'),
            label: 'Ghi chú',
            controller: widget.noteController,
            maxLines: 3,
            maxLength: 500,
            onChanged: widget.cubit.updateNote,
          ),

          if (widget.isEdit &&
              widget.lastUpdatedAt != null &&
              widget.lastUpdatedBy != null) ...[
            const VGap.lg(),
            PriceRuleFormLastUpdatedCard(
              updatedAt: widget.lastUpdatedAt!,
              updatedBy: widget.lastUpdatedBy!,
            ),
          ],

          const VGap.xl(),
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.isRequired = false,
    this.enabled = true,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool isRequired;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AbsorbPointer(
        child: VTextField(
          label: label,
          isRequired: isRequired,
          controller: controller,
          hintText: hintText,
          enabled: enabled,
          state: enabled ? VComponentState.enabled : VComponentState.disabled,
          suffixIcon: VIcon(
            icon: VIcons.chevronRight,
            size: 20,
            color: colors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _FormWarnings extends StatelessWidget {
  const _FormWarnings({
    required this.form,
    required this.onViewConflictingRule,
  });

  final PriceRuleFormEditing form;
  final ValueChanged<String>? onViewConflictingRule;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[
      if (form.isBelowFloor) const PriceRuleBelowFloorBanner(),
      if (form.hasConflictingRule)
        const VBanner(
          tone: VComponentTone.info,
          icon: VIcons.info,
          title: 'Lưu ý tự động ghi đè giá trùng',
          message:
              'Khoảng thời gian hiệu lực mới bị trùng với giá riêng đang áp dụng khác. Khi lưu, hệ thống sẽ tự động ghi đè giá riêng cũ.',
        ),
    ];
    if (widgets.isEmpty) {
      // Giữ một slot cố định để tránh xáo trộn vị trí subtree form khi warning bật/tắt.
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widgets.length; i++) ...[
          if (i > 0) const VGap.md(),
          widgets[i],
        ],
        const VGap.md(),
      ],
    );
  }
}
