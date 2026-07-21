import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

/// S3 — Chi tiết & Thao tác (US-02).
///
/// SG-01: Tên sản phẩm = productName.
/// SG-02: Nút Thao tác là primary button.
class PricingDetailPage extends StatefulWidget {
  const PricingDetailPage({super.key, required this.ruleId});

  final String ruleId;

  @override
  State<PricingDetailPage> createState() => _PricingDetailPageState();
}

class _PricingDetailPageState extends State<PricingDetailPage> {
  late final PriceRuleDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PriceRuleDetailCubit(
      pricingModule: GetIt.instance<IPricingModule>(),
      executionContext: GetIt.instance<IExecutionContext>(),
    )..loadDetail(ruleId: widget.ruleId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<PriceRuleDetailCubit, PriceRuleDetailState>(
        builder: (context, state) {
          return VPageScaffold(
            key: const Key('wgt_e02_u03_fr01_01'),
            title: 'Chi tiết giá riêng',
            subtitle: switch (state) {
              PriceRuleDetailLoaded(:final rule) ||
              PriceRuleDetailActionSuccess(:final rule) =>
                rule.customer.displayName,
              _ => null,
            },
            showBackButton: true,
            body: _PriceRuleDetailBody(
              state: state,
              ruleId: widget.ruleId,
              onRetry: () => _cubit.loadDetail(ruleId: widget.ruleId),
              onViewHistory: (ruleId) =>
                  context.push('/pricing/$ruleId/history'),
            ),
            bottomBar: switch (state) {
              PriceRuleDetailLoaded(:final rule) ||
              PriceRuleDetailActionSuccess(:final rule) =>
                _BottomBar(rule: rule, cubit: _cubit),
              _ => null,
            },
          );
        },
      ),
    );
  }
}

class _PriceRuleDetailBody extends StatelessWidget {
  const _PriceRuleDetailBody({
    required this.state,
    required this.ruleId,
    required this.onRetry,
    required this.onViewHistory,
  });

  final PriceRuleDetailState state;
  final String ruleId;
  final VoidCallback onRetry;
  final ValueChanged<String> onViewHistory;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      PriceRuleDetailInitial() || PriceRuleDetailLoading() =>
        const VSkeletonScope(
          child: Padding(
            padding: EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VSkeleton(width: double.infinity, height: 120),
                VGap.md(),
                VSkeleton(width: double.infinity, height: 160),
                VGap.md(),
                VSkeleton(width: double.infinity, height: 100),
              ],
            ),
          ),
        ),
      PriceRuleDetailNotFound() => const VEmptyState(
          icon: VIcons.search,
          title: 'Không tìm thấy',
          description: 'Mức giá riêng này không tồn tại hoặc đã bị xóa.',
        ),
      PriceRuleDetailNoPermission() => const VEmptyState(
          icon: VIcons.lock,
          title: 'Không có quyền truy cập',
          description: 'Bạn không có quyền xem mức giá riêng này.',
        ),
      PriceRuleDetailError(:final message) => VEmptyState(
          icon: VIcons.error,
          title: 'Đã xảy ra lỗi',
          description: message,
          actionLabel: 'Thử lại',
          onActionPressed: onRetry,
        ),
      PriceRuleDetailLoaded(:final rule, :final recentActivities) ||
      PriceRuleDetailActionSuccess(:final rule, :final recentActivities) =>
        PriceRuleDetailContent(
          rule: rule,
          recentActivities: recentActivities,
          onViewHistory: () => onViewHistory(rule.id),
        ),
    };
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.rule, required this.cubit});

  final CustomerPriceRuleDetailDto rule;
  final PriceRuleDetailCubit cubit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(VSpacing.space4),
        // SG-02: CTA primary button
        child: VButton(
          label: 'Thao tác',
          variant: VButtonVariant.primary,
          fullWidth: true,
          onPressed: () => PriceRuleActionSheet.show(
            context: context,
            rule: rule,
            onEdit: () async {
              final updated = await context.push<CustomerPriceRuleDetailDto>(
                '/pricing/${rule.id}/edit',
                extra: rule,
              );
              if (updated != null && context.mounted) {
                cubit.loadDetail(ruleId: rule.id);
              }
            },
            onDisable: () => PriceRuleDisableSheet.show(
              context: context,
              rule: rule,
              cubit: cubit,
            ),
            onReenable: () => PriceRuleReenableSheet.show(
              context: context,
              rule: rule,
              cubit: cubit,
            ),
            onHistory: () => context.push('/pricing/${rule.id}/history'),
          ),
        ),
      ),
    );
  }
}
