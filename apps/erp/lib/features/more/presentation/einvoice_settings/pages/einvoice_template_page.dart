import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/einvoice_settings_cubit.dart';
import '../bloc/einvoice_settings_state.dart';

class EInvoiceTemplatePage extends StatefulWidget {
  const EInvoiceTemplatePage({super.key, required this.cubit});

  final EInvoiceSettingsCubit cubit;

  @override
  State<EInvoiceTemplatePage> createState() => _EInvoiceTemplatePageState();
}

class _EInvoiceTemplatePageState extends State<EInvoiceTemplatePage> {
  String? _selectedTemplate;

  final List<String> _mockTemplates = [
    'Mẫu 01GTKT0/001 (Ký hiệu: 1C22TML) - Hóa đơn GTGT',
    'Mẫu 01GTKT0/002 (Ký hiệu: 1C23TML) - Hóa đơn GTGT nông nghiệp',
    'Mẫu 02GTTT0/001 (Ký hiệu: 2C22TML) - Hóa đơn bán hàng lẻ',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.cubit.state.selectedTemplate ?? _mockTemplates.first;
  }

  void _showToast(BuildContext context, String message) {
    final colors = context.vColors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: VText(
          message,
          variant: VTextVariant.bodyDefault,
          color: context.vColors.surface,
        ),
        backgroundColor: colors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.card),
        ),
        margin: const EdgeInsets.all(VSpacing.space4),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedTemplate == null) return;

    final success = await widget.cubit.saveTemplate(_selectedTemplate!);

    if (!mounted) return;

    if (success) {
      _showToast(context, 'Đã lưu mẫu hóa đơn mặc định thành công!');
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<EInvoiceSettingsCubit, EInvoiceSettingsState>(
        builder: (context, state) {
          final isConnected = state.misaConnected;

          if (!isConnected) {
            return VPageScaffold(
              title: 'Chọn mẫu hóa đơn',
              showBackButton: true,
              body: Padding(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    const VIcon(
                      icon: VIcons.warning,
                      color: VColors.warning,
                      size: 64,
                    ),
                    const SizedBox(height: VSpacing.space4),
                    VText(
                      'Cần kết nối MISA meInvoice trước khi chọn mẫu hóa đơn.',
                      textAlign: TextAlign.center,
                      variant: VTextVariant.bodyDefault,
                      color: colors.textPrimary,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    VButton(
                      label: 'Đi tới kết nối',
                      fullWidth: true,
                      onPressed: () {
                        context.pushReplacement(
                          '/more/einvoice-settings/connection',
                          extra: context.read<EInvoiceSettingsCubit>(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return VPageScaffold(
            title: 'Chọn mẫu hóa đơn',
            showBackButton: !state.isSubmitting,
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.screenMobile,
                      vertical: VSpacing.space4,
                    ),
                    children: [
                      const SizedBox(height: VSpacing.space1),
                      VText(
                        'Chọn mẫu hóa đơn điện tử mặc định dùng để phát hành hóa đơn cho các đơn hàng tiếp theo.',
                        variant: VTextVariant.bodyDefault,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(height: VSpacing.space4),

                      RadioGroup<String>(
                        groupValue: _selectedTemplate,
                        onChanged: (value) {
                          setState(() {
                            _selectedTemplate = value;
                          });
                        },
                        child: Column(
                          children: _mockTemplates.map((template) {
                            final isSelected = _selectedTemplate == template;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: VSpacing.space3),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(VRadius.card),
                                  border: Border.all(
                                    color: isSelected ? colors.primary : colors.borderDefault,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: state.isSubmitting
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedTemplate = template;
                                          });
                                        },
                                  borderRadius: BorderRadius.circular(VRadius.card),
                                  child: Padding(
                                    padding: const EdgeInsets.all(VSpacing.space4),
                                    child: Row(
                                      children: [
                                        Radio<String>(
                                          value: template,
                                          enabled: !state.isSubmitting,
                                          activeColor: colors.primary,
                                        ),
                                        const SizedBox(width: VSpacing.space2),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              VText(
                                                template.split(' - ').first,
                                                variant: VTextVariant.bodyDefault,
                                                color: colors.textPrimary,
                                                style: const TextStyle(fontWeight: FontWeight.w700),
                                              ),
                                              const SizedBox(height: VSpacing.space1),
                                              VText(
                                                template.split(' - ').last,
                                                variant: VTextVariant.bodySmall,
                                                color: colors.textSecondary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(top: BorderSide(color: colors.borderDefault)),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    VSpacing.space4,
                    VSpacing.space3,
                    VSpacing.space4,
                    VSpacing.space3 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: VButton(
                    label: 'LƯU CẤU HÌNH',
                    isLoading: state.isSubmitting,
                    fullWidth: true,
                    onPressed: state.isSubmitting || _selectedTemplate == null ? null : _submit,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
