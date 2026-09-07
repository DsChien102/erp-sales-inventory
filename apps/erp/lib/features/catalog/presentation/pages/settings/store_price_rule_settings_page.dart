import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

class StorePriceRuleSettingsPage extends StatelessWidget {
  const StorePriceRuleSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StorePriceRuleSettingsCubit(
        moduleMediator: GetIt.instance<ICatalogModule>(),
        executionContext: GetIt.instance<IExecutionContext>(),
      )..loadRule(),
      child: const _StorePriceRuleSettingsBody(),
    );
  }
}

class _StorePriceRuleSettingsBody extends StatelessWidget {
  const _StorePriceRuleSettingsBody();

  @override
  Widget build(BuildContext context) {
    return VPageScaffold(
      title: 'Giá sàn & Giá niêm yết',
      showBackButton: true,
      body: BlocConsumer<StorePriceRuleSettingsCubit, StorePriceRuleSettingsState>(
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
          if (state is StorePriceRuleSettingsLoading || state is StorePriceRuleSettingsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          StorePriceRuleDto? rule;
          String? errorMessage;
          if (state is StorePriceRuleSettingsLoaded) {
            rule = state.rule;
          } else if (state is StorePriceRuleSettingsSaving) {
            rule = state.previousRule;
          } else if (state is StorePriceRuleSettingsError) {
            rule = state.previousRule;
            errorMessage = state.message;
          }

          return _buildContent(
            context,
            rule: rule,
            errorMessage: errorMessage,
            onRetry: errorMessage != null
                ? () => context.read<StorePriceRuleSettingsCubit>().loadRule()
                : null,
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required StorePriceRuleDto? rule,
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space4,
      ),
      children: [
        if (errorMessage != null) ...[
          _buildErrorBanner(
            context,
            message: errorMessage,
            onRetry: onRetry,
          ),
          const SizedBox(height: VSpacing.space4),
        ],
        // — Top info card "Khung giá cửa hàng"
        _buildInfoCard(context),
        const SizedBox(height: VSpacing.space5),

        // — Section "CẤU HÌNH HIỆN TẠI"
        _buildCurrentConfigSection(context, rule),
        const SizedBox(height: VSpacing.space5),

        // — Lưu ý info
        _buildNoteCard(context),
        const SizedBox(height: VSpacing.space4),

        // — Lịch sử thay đổi
        _buildChangeHistoryCard(context),
      ],
    );
  }

  Widget _buildErrorBanner(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    final colors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: colors.dangerBg,
        borderRadius: BorderRadius.circular(VRadius.r12),
        border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VIcon(icon: VIcons.error, size: 18, color: colors.danger),
          const SizedBox(width: VSpacing.space2),
          Expanded(
            child: VText(
              message,
              variant: VTextVariant.bodySmall,
              color: colors.danger,
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const VText('Thử lại'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final colors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.r12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VIconBox(
            icon: VIcons.store,
            size: 44,
            iconSize: 22,
            backgroundColor: colors.surfaceBrand,
            iconColor: colors.primary,
            borderRadius: VRadius.r12,
          ),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Khung giá cửa hàng',
                  variant: VTextVariant.headingH4,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: VSpacing.space1),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Các đơn vị chọn '),
                      TextSpan(
                        text: '"Theo khung giá cửa hàng"',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text:
                            ' sẽ tự động áp dụng tỷ lệ dưới đây để tính Giá niêm yết và Giá sàn từ Giá cơ sở.',
                      ),
                    ],
                  ),
                  style: VTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentConfigSection(BuildContext context, StorePriceRuleDto? rule) {
    final colors = context.vColors;

    final hasRule = rule != null;
    final listMarkupPercent = hasRule ? (rule.listMarkupRatio * 100).toStringAsFixed(1) : null;
    final floorMarkupPercent = hasRule ? (rule.floorMarkupRatio * 100).toStringAsFixed(1) : null;

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
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VText(
                'CẤU HÌNH HIỆN TẠI',
                style: VTypography.caption.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              InkWell(
                onTap: () async {
                  final didChange = await context.push<bool>(
                    '/more/product-settings/store-price-rule/edit',
                    extra: rule,
                  );
                  if (didChange == true && context.mounted) {
                    context.read<StorePriceRuleSettingsCubit>().loadRule();
                  }
                },
                borderRadius: BorderRadius.circular(VRadius.r8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.space2,
                    vertical: VSpacing.space1,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VIcon(icon: VIcons.edit, size: 16, color: colors.primary),
                      const VGap.horizontalXs(),
                      VText(
                        'Sửa',
                        variant: VTextVariant.bodyDefault,
                        color: colors.primary,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space4),
          if (!hasRule)
            Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.space3),
              child: VText(
                'Chưa cấu hình khung giá cửa hàng. Nhấn Sửa để thiết lập tỷ lệ lãi và giá sàn.',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ),

          // Giá niêm yết row
          _buildRatioRow(
            context,
            icon: VIcons.trendingUp,
            iconColor: colors.success,
            iconBgColor: colors.successBg,
            label: 'Giá niêm yết',
            sublabel: 'Tỷ lệ lãi so với Giá cơ sở',
            valueText: listMarkupPercent != null ? '+$listMarkupPercent%' : '—',
            valueColor: colors.success,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: VSpacing.space3),
            child: Divider(height: 1, color: colors.borderDefault),
          ),

          // Giá sàn row
          _buildRatioRow(
            context,
            icon: VIcons.trendingDown,
            iconColor: colors.danger,
            iconBgColor: colors.dangerBg,
            label: 'Giá sàn',
            sublabel: 'Tỷ lệ sàn so với Giá cơ sở',
            valueText: floorMarkupPercent != null ? '$floorMarkupPercent%' : '—',
            valueColor: colors.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildRatioRow(
    BuildContext context, {
    required VIcons icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String sublabel,
    required String valueText,
    required Color valueColor,
  }) {
    final colors = context.vColors;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(VRadius.r8),
          ),
          child: VIcon(icon: icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: VSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText(
                label,
                variant: VTextVariant.bodyDefault,
                color: colors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const VGap.xs(),
              VText(
                sublabel,
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
        VText(
          valueText,
          style: VTypography.headingH4.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(BuildContext context) {
    final colors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.warningBg,
        borderRadius: BorderRadius.circular(VRadius.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VIcon(icon: VIcons.info, size: 18, color: colors.warning),
              const SizedBox(width: VSpacing.space2),
              VText(
                'Lưu ý',
                variant: VTextVariant.bodyDefault,
                color: colors.warning,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space2),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBullet(
                  context,
                  'Giá sẽ tự cập nhật cho các đơn vị chọn ',
                  boldPart: '"Theo khung giá cửa hàng"',
                  afterBold: '.',
                ),
                const SizedBox(height: VSpacing.space2),
                _buildBullet(
                  context,
                  'Không áp dụng cho đơn vị chọn ',
                  boldPart: '"Tự động riêng theo cấu hình"',
                  afterBold: ' hoặc ',
                  boldPart2: '"Nhập thủ công"',
                  afterBold2: '.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(
    BuildContext context,
    String text, {
    String? boldPart,
    String? afterBold,
    String? boldPart2,
    String? afterBold2,
  }) {
    final colors = context.vColors;

    final spans = <InlineSpan>[
      const WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: EdgeInsets.only(right: 8),
          child: VIcon(icon: VIcons.circle, size: 6),
        ),
      ),
      TextSpan(text: text),
    ];

    if (boldPart != null) {
      spans.add(
        TextSpan(
          text: boldPart,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }
    if (afterBold != null) {
      spans.add(TextSpan(text: afterBold));
    }
    if (boldPart2 != null) {
      spans.add(
        TextSpan(
          text: boldPart2,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }
    if (afterBold2 != null) {
      spans.add(TextSpan(text: afterBold2));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: VTypography.bodySmall.copyWith(
        color: colors.textPrimary,
      ),
    );
  }

  Widget _buildChangeHistoryCard(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      onTap: () => context.push('/more/product-settings/store-price-rule/history'),
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space3 + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceBrand,
              borderRadius: BorderRadius.circular(VRadius.r8),
            ),
            child: VIcon(icon: VIcons.history, size: 20, color: colors.primary),
          ),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Lịch sử thay đổi',
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const VGap.xs(),
                VText(
                  'Xem các thay đổi khung giá cửa hàng',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          VIcon(
            icon: VIcons.chevronRight,
            color: colors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
