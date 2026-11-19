import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../data/models.dart';
import '../../../data/product_price_repository.dart';

import '../../widgets/product_form_bottom_bar.dart';
import '../../widgets/store_price_rule_save_confirm_sheet.dart';

class EditStorePriceRulePage extends StatefulWidget {
  const EditStorePriceRulePage({
    super.key,
    this.existingRule,
  });

  final StorePriceRuleDto? existingRule;

  @override
  State<EditStorePriceRulePage> createState() => _EditStorePriceRulePageState();
}

class _EditStorePriceRulePageState extends State<EditStorePriceRulePage> {
  late final TextEditingController _listMarkupController;
  late final TextEditingController _floorMarkupController;
  late final TextEditingController _basePriceExampleController;

  static const double _defaultExampleBasePrice = 100000;

  @override
  void initState() {
    super.initState();
    final rule = widget.existingRule;
    _listMarkupController = TextEditingController(
      text: rule != null ? (rule.listMarkupRatio * 100).toStringAsFixed(1) : '',
    );
    _floorMarkupController = TextEditingController(
      text: rule != null ? (rule.floorMarkupRatio * 100).toStringAsFixed(1) : '',
    );
    _basePriceExampleController = TextEditingController(
      text: formatCatalogCurrencyAmount(_defaultExampleBasePrice) ?? '',
    );
  }

  @override
  void dispose() {
    _listMarkupController.dispose();
    _floorMarkupController.dispose();
    _basePriceExampleController.dispose();
    super.dispose();
  }

  double? _parseListMarkup() {
    final text = _listMarkupController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  double? _parseFloorMarkup() {
    final text = _floorMarkupController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  bool _isNonNegative(double? value) => value != null && value >= 0;

  double _parseExampleBasePrice() {
    return (parseCatalogCurrencyAmount(_basePriceExampleController.text) ??
            _defaultExampleBasePrice.toInt())
        .toDouble();
  }

  double? _calculatePreviewPrice(double basePrice, double? markupPercent) {
    if (markupPercent == null) return null;
    return (basePrice * (1 + markupPercent / 100)).roundToDouble();
  }

  bool get _hasChanges {
    final rule = widget.existingRule;
    if (rule == null) return true;
    final listMarkup = _parseListMarkup();
    final floorMarkup = _parseFloorMarkup();
    if (listMarkup == null || floorMarkup == null) return true;

    final listChanged = (listMarkup / 100 - rule.listMarkupRatio).abs() > 1e-6;
    final floorChanged = (floorMarkup / 100 - rule.floorMarkupRatio).abs() > 1e-6;
    return listChanged || floorChanged;
  }

  bool get _canSubmit {
    final listMarkup = _parseListMarkup();
    final floorMarkup = _parseFloorMarkup();
    return _isNonNegative(listMarkup) &&
        _isNonNegative(floorMarkup) &&
        floorMarkup! <= listMarkup! &&
        _hasChanges;
  }

  String? _markupFieldError({
    required double? value,
    required double? peerListMarkup,
    required bool isFloorField,
  }) {
    if (value != null && value < 0) {
      return 'Giá trị phải lớn hơn hoặc bằng 0';
    }
    if (isFloorField && value != null && peerListMarkup != null && value > peerListMarkup) {
      return 'Giá sàn không được lớn hơn giá niêm yết.';
    }
    return null;
  }

  void _adjustValue(TextEditingController controller, double delta) {
    final current = double.tryParse(controller.text.trim()) ?? 0;
    final newVal = (current + delta).clamp(0, double.infinity).toDouble();
    controller.text = newVal.toStringAsFixed(1);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StorePriceRuleSettingsCubit(
        productPriceRepository: GetIt.instance<ProductPriceRepository>(),
      ),
      child: BlocConsumer<StorePriceRuleSettingsCubit, StorePriceRuleSettingsState>(
        listener: (context, state) {
          if (state is StorePriceRuleSettingsError) {
            VToast.show(
              context,
              title: 'Lỗi',
              message: state.message,
              type: VToastType.danger,
            );
          }
        },
        builder: (context, state) {
          final isSaving = state is StorePriceRuleSettingsSaving;

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: VPageScaffold(
              title: 'Chỉnh sửa khung giá',
              showBackButton: true,
              resizeToAvoidBottomInset: true,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBanner(context),
                    const SizedBox(height: VSpacing.space5),
                    _buildMarkupInput(
                      context,
                      label: 'Giá niêm yết (tỷ lệ lãi)',
                      controller: _listMarkupController,
                      helperText: 'Tính theo % trên Giá cơ sở',
                      errorText: _markupFieldError(
                        value: _parseListMarkup(),
                        peerListMarkup: null,
                        isFloorField: false,
                      ),
                    ),
                    const SizedBox(height: VSpacing.space5),
                    _buildMarkupInput(
                      context,
                      label: 'Giá sàn (tỷ lệ sàn)',
                      controller: _floorMarkupController,
                      helperText: 'Tính theo % trên Giá cơ sở',
                      errorText: _markupFieldError(
                        value: _parseFloorMarkup(),
                        peerListMarkup: _parseListMarkup(),
                        isFloorField: true,
                      ),
                    ),
                    const SizedBox(height: VSpacing.space5),
                    _buildPreviewSection(context),
                  ],
                ),
              ),
              bottomBar: ProductFormBottomBar(
                onCancel: () => context.pop(),
                isLoading: isSaving,
                saveEnabled: _canSubmit,
                onSave: () async {
                  final confirmed = await showStorePriceRuleSaveConfirmSheet(context);
                  if (confirmed != true || !context.mounted) return;

                  final listMarkup = _parseListMarkup()!;
                  final floorMarkup = _parseFloorMarkup()!;
                  final success = await context.read<StorePriceRuleSettingsCubit>().saveRule(
                    listMarkupRatio: listMarkup / 100,
                    floorMarkupRatio: floorMarkup / 100,
                  );
                  if (!context.mounted || !success) {
                    return;
                  }
                  VToast.show(
                    context,
                    title: 'Thành công',
                    message: 'Đã cập nhật khung giá cửa hàng.',
                    type: VToastType.success,
                  );
                  context.pop(true);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    final colors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: colors.warningBg,
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(VRadius.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VIcon(icon: VIcons.info, size: 18, color: colors.warning),
          const SizedBox(width: VSpacing.space2),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Tỷ lệ dưới đây sẽ được áp dụng cho mọi đơn vị chọn '),
                  TextSpan(
                    text: '"Theo khung giá cửa hàng"',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              style: VTypography.bodySmall.copyWith(
                color: colors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkupInput(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String helperText,
    String? errorText,
  }) {
    final colors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(
          label,
          variant: VTextVariant.bodyDefault,
          color: colors.textPrimary,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const VGap.sm(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: VTextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (_) => setState(() {}),
                suffixText: '%',
                helperText: helperText,
                errorText: errorText,
                textStyle: VTypography.headingH4.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const VGap.horizontalSm(),
            Column(
              children: [
                _buildAdjustButton(
                  context,
                  icon: VIcons.chevronUp,
                  onTap: () => _adjustValue(controller, 0.1),
                ),
                const VGap.xs(),
                _buildAdjustButton(
                  context,
                  icon: VIcons.chevronDown,
                  onTap: () => _adjustValue(controller, -0.1),
                ),
              ],
            ),
          ],
        ),
        const VGap.xs(),
        VText(
          helperText,
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildAdjustButton(
    BuildContext context, {
    required VIcons icon,
    required VoidCallback onTap,
  }) {
    final colors = context.vColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VRadius.r8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: colors.borderDefault),
          borderRadius: BorderRadius.circular(VRadius.r8),
        ),
        child: VIcon(icon: icon, size: 20, color: colors.textSecondary),
      ),
    );
  }

  Widget _buildPreviewSection(BuildContext context) {
    final colors = context.vColors;
    final exampleBase = _parseExampleBasePrice();
    final listMarkup = _parseListMarkup();
    final floorMarkup = _parseFloorMarkup();
    final previewList = _calculatePreviewPrice(exampleBase, listMarkup);
    final previewFloor = _calculatePreviewPrice(exampleBase, floorMarkup);

    return Container(
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.r12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            'XEM TRƯỚC VỚI VÍ DỤ',
            style: VTypography.caption.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: VSpacing.space3),

          // Giá cơ sở (ví dụ) input
          VText(
            'Giá cơ sở (ví dụ)',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          const SizedBox(height: VSpacing.space2),
          VMoneyField(
            controller: _basePriceExampleController,
            suffixText: 'đ',
            textStyle: VTypography.headingH4.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: VSpacing.space3),

          // Giá niêm yết (dự kiến)
          _buildPreviewRow(
            context,
            label: 'Giá niêm yết (dự kiến)',
            value: previewList,
            valueColor: colors.success,
          ),
          const SizedBox(height: VSpacing.space2),

          // Giá sàn (dự kiến)
          _buildPreviewRow(
            context,
            label: 'Giá sàn (dự kiến)',
            value: previewFloor,
            valueColor: colors.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(
    BuildContext context, {
    required String label,
    required double? value,
    required Color valueColor,
  }) {
    final colors = context.vColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          label,
          variant: VTextVariant.bodyDefault,
          color: colors.textSecondary,
        ),
        VText(
          value != null ? formatCatalogCurrency(value) : '—',
          style: VTypography.bodyDefault.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
