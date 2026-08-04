import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/einvoice_settings_cubit.dart';
import '../bloc/einvoice_settings_state.dart';

class EInvoiceAutoPage extends StatefulWidget {
  const EInvoiceAutoPage({super.key, required this.cubit});

  final EInvoiceSettingsCubit cubit;

  @override
  State<EInvoiceAutoPage> createState() => _EInvoiceAutoPageState();
}

class _EInvoiceAutoPageState extends State<EInvoiceAutoPage> {
  late bool _autoIssue;
  late bool _autoSend;

  @override
  void initState() {
    super.initState();
    final state = widget.cubit.state;
    _autoIssue = state.autoIssue;
    _autoSend = state.autoSend;
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
    final success = await widget.cubit.saveAutoSettings(
      autoIssue: _autoIssue,
      autoSend: _autoSend,
    );

    if (!mounted) return;

    if (success) {
      _showToast(context, 'Đã lưu cấu hình tự động hóa đơn điện tử!');
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
          final isMisaConnected = state.misaConnected;
          final isTemplateSelected = state.selectedTemplate != null;

          // Disable auto-issue toggle if MISA is not connected OR template is not selected
          final canToggleAutoIssue = isMisaConnected && isTemplateSelected;
          // Disable auto-send toggle if MISA is not connected
          final canToggleAutoSend = isMisaConnected;

          return VPageScaffold(
            title: 'Cấu hình phát hành & gửi',
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.screenMobile,
                      vertical: VSpacing.space4,
                    ),
                    children: [
                      // Toggle 1: Auto Issue
                      Opacity(
                        opacity: canToggleAutoIssue ? 1.0 : 0.5,
                        child: VCard(
                          padding: const EdgeInsets.all(VSpacing.space4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        VText(
                                          'Tự động phát hành HĐĐT',
                                          variant: VTextVariant.bodyDefault,
                                          color: colors.textPrimary,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: VSpacing.space1),
                                        VText(
                                          'Hệ thống tự động phát hành HĐĐT sau khi tạo đơn hàng thành công nếu đơn hàng đủ điều kiện.',
                                          variant: VTextVariant.bodySmall,
                                          color: colors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: VSpacing.space3),
                                  VSwitch(
                                    value: canToggleAutoIssue ? _autoIssue : false,
                                    onChanged: (canToggleAutoIssue && !state.isSubmitting)
                                        ? (value) {
                                            setState(() {
                                              _autoIssue = value;
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                              if (!isMisaConnected) ...[
                                const SizedBox(height: VSpacing.space2),
                                Divider(color: colors.borderDefault, height: 1),
                                const SizedBox(height: VSpacing.space2),
                                Row(
                                  children: [
                                    VIcon(
                                      icon: VIcons.info,
                                      color: colors.warning,
                                      size: 16,
                                    ),
                                    const VGap.horizontalSm(),
                                    Expanded(
                                      child: VText(
                                        'Cần kết nối MISA meInvoice trước.',
                                        variant: VTextVariant.bodySmall,
                                        color: colors.warning,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (!isTemplateSelected) ...[
                                const SizedBox(height: VSpacing.space2),
                                Divider(color: colors.borderDefault, height: 1),
                                const SizedBox(height: VSpacing.space2),
                                Row(
                                  children: [
                                    VIcon(
                                      icon: VIcons.info,
                                      color: colors.warning,
                                      size: 16,
                                    ),
                                    const VGap.horizontalSm(),
                                    Expanded(
                                      child: VText(
                                        'Vui lòng chọn mẫu hóa đơn mặc định trước.',
                                        variant: VTextVariant.bodySmall,
                                        color: colors.warning,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: VSpacing.space4),

                      // Toggle 2: Auto Send
                      Opacity(
                        opacity: canToggleAutoSend ? 1.0 : 0.5,
                        child: VCard(
                          padding: const EdgeInsets.all(VSpacing.space4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        VText(
                                          'Tự động gửi HĐĐT cho khách',
                                          variant: VTextVariant.bodyDefault,
                                          color: colors.textPrimary,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: VSpacing.space1),
                                        VText(
                                          'Hệ thống tự động gửi HĐĐT cho khách sau khi HĐĐT phát hành thành công và khách hàng có email hợp lệ.',
                                          variant: VTextVariant.bodySmall,
                                          color: colors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: VSpacing.space3),
                                  VSwitch(
                                    value: canToggleAutoSend ? _autoSend : false,
                                    onChanged: (canToggleAutoSend && !state.isSubmitting)
                                        ? (value) {
                                            setState(() {
                                              _autoSend = value;
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                              if (!isMisaConnected) ...[
                                const SizedBox(height: VSpacing.space2),
                                Divider(color: colors.borderDefault, height: 1),
                                const SizedBox(height: VSpacing.space2),
                                Row(
                                  children: [
                                    VIcon(
                                      icon: VIcons.info,
                                      color: colors.warning,
                                      size: 16,
                                    ),
                                    const VGap.horizontalSm(),
                                    Expanded(
                                      child: VText(
                                        'Cần kết nối MISA meInvoice trước.',
                                        variant: VTextVariant.bodySmall,
                                        color: colors.warning,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: VSpacing.space4),

                      // Footer Note
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: VSpacing.space2),
                        child: VText(
                          'Hai cấu hình này độc lập. Cấu hình mới chỉ áp dụng cho các đơn hàng tạo thành công sau thời điểm cấu hình có hiệu lực.',
                          style: VTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
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
                    label: 'Lưu cấu hình',
                    isLoading: state.isSubmitting,
                    fullWidth: true,
                    onPressed: state.isSubmitting ? null : _submit,
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
