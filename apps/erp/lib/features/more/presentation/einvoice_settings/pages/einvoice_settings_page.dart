import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/einvoice_settings_cubit.dart';
import '../bloc/einvoice_settings_state.dart';

class EInvoiceSettingsPage extends StatelessWidget {
  const EInvoiceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EInvoiceSettingsCubit>(
      create: (_) => EInvoiceSettingsCubit()..loadSettings(),
      child: const _EInvoiceSettingsView(),
    );
  }
}

class _EInvoiceSettingsView extends StatelessWidget {
  const _EInvoiceSettingsView();

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocBuilder<EInvoiceSettingsCubit, EInvoiceSettingsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return VPageScaffold(
            title: 'Thiết lập hóa đơn điện tử',
            showBackButton: true,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
          );
        }

        return VPageScaffold(
          title: 'Thiết lập hóa đơn điện tử',
          body: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.screenMobile,
              vertical: VSpacing.space4,
            ),
            children: [
              // Card 1: Connection
              _SettingsItemCard(
                icon: VIcons.power,
                title: 'Kết nối dịch vụ hóa đơn điện tử',
                subtitle: 'Nhà cung cấp: MISA meInvoice',
                badge: state.misaConnected
                    ? null
                    : const VBadge(
                        label: 'CHƯA KẾT NỐI',
                        status: VBadgeStatus.draft,
                      ),
                content: state.misaConnected
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const VBadge(
                                label: 'ĐANG KẾT NỐI',
                                status: VBadgeStatus.completed,
                              ),
                              const SizedBox(width: VSpacing.space2),
                            ],
                          ),
                          const SizedBox(height: VSpacing.space1),
                          VText(
                            'Cập nhật bởi: ${state.updatedBy ?? ''}',
                            variant: VTextVariant.bodySmall,
                            color: colors.textSecondary,
                          ),
                          VText(
                            'Kiểm tra: ${state.lastChecked != null ? _formatDateTime(state.lastChecked!) : ''}',
                            variant: VTextVariant.bodySmall,
                            color: colors.textSecondary,
                          ),
                        ],
                      )
                    : null,
                actionText: state.misaConnected ? 'Cập nhật kết nối' : 'Cấu hình kết nối',
                onTap: () async {
                  final result = await context.push<bool>(
                    '/more/einvoice-settings/connection',
                    extra: context.read<EInvoiceSettingsCubit>(),
                  );
                  if (result == true && context.mounted) {
                    context.read<EInvoiceSettingsCubit>().loadSettings();
                  }
                },
              ),
              const SizedBox(height: VSpacing.space4),

              // Card 2: Default template
              _SettingsItemCard(
                icon: VIcons.gridView,
                title: 'Mẫu hóa đơn mặc định',
                subtitle: state.misaConnected
                    ? (state.selectedTemplate ?? 'Chưa chọn mẫu hóa đơn')
                    : 'Cần kết nối MISA meInvoice trước',
                actionText: 'Chọn mẫu hóa đơn',
                onTap: () async {
                  final result = await context.push<bool>(
                    '/more/einvoice-settings/template',
                    extra: context.read<EInvoiceSettingsCubit>(),
                  );
                  if (result == true && context.mounted) {
                    context.read<EInvoiceSettingsCubit>().loadSettings();
                  }
                },
              ),
              const SizedBox(height: VSpacing.space4),

              // Card 3: Auto-issuance and auto-send
              _SettingsItemCard(
                icon: VIcons.bolt,
                title: 'Phát hành và gửi hóa đơn',
                showDivider: false,
                content: Padding(
                  padding: const EdgeInsets.only(top: VSpacing.space3),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          VText(
                            'Tự động phát hành HĐĐT',
                            variant: VTextVariant.bodySmall,
                            color: colors.textSecondary,
                          ),
                          VBadge(
                            label: state.autoIssue ? 'Bật' : 'Tắt',
                            status: state.autoIssue ? VBadgeStatus.completed : VBadgeStatus.draft,
                          ),
                        ],
                      ),
                      const SizedBox(height: VSpacing.space2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          VText(
                            'Tự động gửi HĐĐT cho khách',
                            variant: VTextVariant.bodySmall,
                            color: colors.textSecondary,
                          ),
                          VBadge(
                            label: state.autoSend ? 'Bật' : 'Tắt',
                            status: state.autoSend ? VBadgeStatus.completed : VBadgeStatus.draft,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actionText: 'Cấu hình tự động',
                onTap: () async {
                  final result = await context.push<bool>(
                    '/more/einvoice-settings/auto',
                    extra: context.read<EInvoiceSettingsCubit>(),
                  );
                  if (result == true && context.mounted) {
                    context.read<EInvoiceSettingsCubit>().loadSettings();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsItemCard extends StatelessWidget {
  const _SettingsItemCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.content,
    this.showDivider = false,
    required this.actionText,
    required this.onTap,
  });

  final VIcons icon;
  final String title;
  final String? subtitle;
  final Widget? badge;
  final Widget? content;
  final bool showDivider;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VIconBox(
            icon: icon,
            size: 40,
            iconSize: 20,
            backgroundColor: colors.successBg,
            iconColor: colors.success,
            borderRadius: VRadius.r12,
          ),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: VText(
                        title,
                        variant: VTextVariant.headingH4,
                        color: colors.textPrimary,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: VSpacing.space1),
                    VIcon(
                      icon: VIcons.chevronRight,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: VSpacing.space1),
                  VText(
                    subtitle!,
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
                if (badge != null) ...[
                  const VGap.sm(),
                  badge!,
                ],
                if (content != null) ...[
                  const SizedBox(height: VSpacing.space2),
                  content!,
                ],
                if (showDivider) ...[
                  const SizedBox(height: VSpacing.space4),
                  Divider(color: colors.borderDefault, height: 1),
                  const SizedBox(height: VSpacing.space3),
                ] else ...[
                  const SizedBox(height: VSpacing.space3),
                ],
                VText(
                  actionText,
                  variant: VTextVariant.bodyDefault,
                  color: colors.success,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
