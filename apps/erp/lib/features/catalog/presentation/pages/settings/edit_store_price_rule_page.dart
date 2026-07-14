import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

import '../../widgets/product_form_bottom_bar.dart';

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
  late final TextEditingController _noteController;

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
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _listMarkupController.dispose();
    _floorMarkupController.dispose();
    _basePriceExampleController.dispose();
    _noteController.dispose();
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

  bool get _canSubmit {
    final listMarkup = _parseListMarkup();
    final floorMarkup = _parseFloorMarkup();
    return _isNonNegative(listMarkup) && _isNonNegative(floorMarkup);
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
        moduleMediator: GetIt.instance<ICatalogModule>(),
        executionContext: GetIt.instance<IExecutionContext>(),
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

          return Scaffold(
            backgroundColor: context.vColors.surface,
            appBar: const VAppBar(
              title: 'Chỉnh sửa khung giá',
              showBackButton: true,
            ),
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
                  ),
                  const SizedBox(height: VSpacing.space5),
                  _buildMarkupInput(
                    context,
                    label: 'Giá sàn (tỷ lệ sàn)',
                    controller: _floorMarkupController,
                    helperText: 'Tính theo % trên Giá cơ sở',
                  ),
                  const SizedBox(height: VSpacing.space5),
                  _buildPreviewSection(context),
                  const SizedBox(height: VSpacing.space5),
                  _buildNoteSection(context),
                ],
              ),
            ),
            bottomNavigationBar: ProductFormBottomBar(
              onCancel: () => context.pop(),
              isLoading: isSaving,
              saveEnabled: _canSubmit,
              onSave: () async {
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
          Icon(Icons.info_outline, size: 18, color: colors.warning),
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
  }) {
    final colors = context.vColors;
    final parsedValue = double.tryParse(controller.text.trim());
    final hasNegativeValue = parsedValue != null && parsedValue < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: VTypography.bodyDefault.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: VSpacing.space2),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (_) => setState(() {}),
                style: VTypography.headingH4.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  suffixText: '%',
                  suffixStyle: VTypography.bodyDefault.copyWith(
                    color: colors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VRadius.r8),
                    borderSide: BorderSide(color: colors.borderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VRadius.r8),
                    borderSide: BorderSide(color: colors.borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VRadius.r8),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.space3,
                    vertical: VSpacing.space3,
                  ),
                  errorText: hasNegativeValue ? 'Giá trị phải lớn hơn hoặc bằng 0' : null,
                ),
              ),
            ),
            const SizedBox(width: VSpacing.space2),
            Column(
              children: [
                _buildAdjustButton(
                  context,
                  icon: Icons.keyboard_arrow_up,
                  onTap: () => _adjustValue(controller, 0.1),
                ),
                const SizedBox(height: 4),
                _buildAdjustButton(
                  context,
                  icon: Icons.keyboard_arrow_down,
                  onTap: () => _adjustValue(controller, -0.1),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: VSpacing.space1),
        Text(
          helperText,
          style: VTypography.bodySmall.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAdjustButton(
    BuildContext context, {
    required IconData icon,
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
        child: Icon(icon, size: 20, color: colors.textSecondary),
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
          Text(
            'XEM TRƯỚC VỚI VÍ DỤ',
            style: VTypography.caption.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: VSpacing.space3),

          // Giá cơ sở (ví dụ) input
          Text(
            'Giá cơ sở (ví dụ)',
            style: VTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
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
        Text(
          label,
          style: VTypography.bodyDefault.copyWith(
            color: colors.textSecondary,
          ),
        ),
        Text(
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

  Widget _buildNoteSection(BuildContext context) {
    final colors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ghi chú (tuỳ chọn)',
          style: VTypography.bodyDefault.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: VSpacing.space2),
        TextField(
          controller: _noteController,
          maxLines: 3,
          style: VTypography.bodyDefault.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'VD: Điều chỉnh theo chiến lược quý',
            hintStyle: VTypography.bodyDefault.copyWith(
              color: colors.textMuted,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VRadius.r8),
              borderSide: BorderSide(color: colors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VRadius.r8),
              borderSide: BorderSide(color: colors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VRadius.r8),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(VSpacing.space3),
          ),
        ),
      ],
    );
  }
}
