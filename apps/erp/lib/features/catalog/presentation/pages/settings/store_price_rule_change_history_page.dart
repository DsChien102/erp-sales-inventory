import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

class StorePriceRuleChangeHistoryPage extends StatelessWidget {
  const StorePriceRuleChangeHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StorePriceRuleSettingsCubit(
        moduleMediator: GetIt.instance<ICatalogModule>(),
        executionContext: GetIt.instance<IExecutionContext>(),
      )..loadRule(),
      child: const _ChangeHistoryBody(),
    );
  }
}

class _ChangeHistoryBody extends StatelessWidget {
  const _ChangeHistoryBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: const VAppBar(
        title: 'Lịch sử thay đổi',
        showBackButton: true,
      ),
      body: BlocBuilder<StorePriceRuleSettingsCubit,
          StorePriceRuleSettingsState>(
        builder: (context, state) {
          if (state is StorePriceRuleSettingsLoading ||
              state is StorePriceRuleSettingsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          StorePriceRuleDto? rule;
          if (state is StorePriceRuleSettingsLoaded) {
            rule = state.rule;
          }

          return _buildContent(context, rule);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, StorePriceRuleDto? rule) {
    final colors = context.vColors;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space4,
      ),
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(VSpacing.space3),
          decoration: BoxDecoration(
            color: colors.surfaceBrand,
            borderRadius: BorderRadius.circular(VRadius.r12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: colors.primary),
              const SizedBox(width: VSpacing.space2),
              Expanded(
                child: Text(
                  'Lịch sử chỉ ghi nhận các thay đổi khung giá cửa hàng.',
                  style: VTypography.bodySmall.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space4),

        // Current rule entry (or empty state)
        if (rule != null) _buildHistoryEntry(context, rule) else _buildEmptyState(context),
      ],
    );
  }

  Widget _buildHistoryEntry(BuildContext context, StorePriceRuleDto rule) {
    final colors = context.vColors;
    final dateText = rule.updatedAt != null
        ? _formatDateTime(rule.updatedAt!)
        : '—';

    final listPercent = (rule.listMarkupRatio * 100).toStringAsFixed(1);
    final floorPercent = (rule.floorMarkupRatio * 100).toStringAsFixed(1);

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
          // Header: date + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateText,
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceBrand,
                  borderRadius: BorderRadius.circular(VRadius.r4),
                ),
                child: Text(
                  'Hiện tại',
                  style: VTypography.caption.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Bởi: Bạn',
            style: VTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: VSpacing.space3),

          // Giá niêm yết
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giá niêm yết',
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              Text(
                '+$listPercent%',
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space2),

          // Giá sàn
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giá sàn',
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Text(
                    '$floorPercent%',
                    style: VTypography.bodyDefault.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(—)',
                    style: VTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.vColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: VSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: colors.textMuted,
            ),
            const SizedBox(height: VSpacing.space3),
            Text(
              'Chưa có lịch sử thay đổi',
              style: VTypography.bodyDefault.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$h:$m $d/$mo/$y';
  }
}
