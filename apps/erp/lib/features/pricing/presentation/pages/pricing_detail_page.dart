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
          final colors = context.vColors;
          return VPageScaffold(
            key: const Key('wgt_e02_u03_fr01_01'),
            title: 'Chi tiết giá riêng',
            subtitle: switch (state) {
              PriceRuleDetailLoaded(:final rule) ||
              PriceRuleDetailActionSuccess(:final rule) =>
                rule.customer.displayName,
              _ => null,
            },
            showBackButton: false,
            leading: IconButton(
              icon: VIcon(icon: VIcons.arrowBack, color: colors.textPrimary),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/pricing');
                }
              },
            ),
            body: _PriceRuleDetailBody(
              state: state,
              ruleId: widget.ruleId,
              onRetry: () => _cubit.loadDetail(ruleId: widget.ruleId),
              onViewHistory: (ruleId) =>
                  context.push('/pricing/$ruleId/history'),
            ),
            bottomBar: switch (state) {
              PriceRuleDetailLoaded(:final rule) ||
              PriceRuleDetailActionSuccess(:final rule)
                  when rule.availableActions.isNotEmpty =>
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
      PriceRuleDetailNotFound() => const Align(
          alignment: Alignment(0.0, -0.3),
          child: VEmptyState(
            icon: VIcons.search,
            title: 'Không tìm thấy',
            description: 'Mức giá riêng này không tồn tại hoặc đã bị xóa.',
          ),
        ),
      PriceRuleDetailNoPermission() => const Align(
          alignment: Alignment(0.0, -0.3),
          child: VEmptyState(
            icon: VIcons.lock,
            title: 'Không có quyền truy cập',
            description: 'Bạn không có quyền xem mức giá riêng này.',
          ),
        ),
      PriceRuleDetailError(:final message) => Align(
          alignment: const Alignment(0.0, -0.3),
          child: VEmptyState(
            icon: VIcons.error,
            title: 'Đã xảy ra lỗi',
            description: message,
            actionLabel: 'Thử lại',
            onActionPressed: onRetry,
          ),
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

class _BottomBar extends StatefulWidget {
  const _BottomBar({required this.rule, required this.cubit});

  final CustomerPriceRuleDetailDto rule;
  final PriceRuleDetailCubit cubit;

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  bool _isOpeningActions = false;

  Future<void> _openActionSheet() async {
    if (_isOpeningActions) return;
    setState(() => _isOpeningActions = true);

    final refreshed = await widget.cubit.refreshDetailForActions(
      ruleId: widget.rule.id,
    );

    if (!mounted) return;
    setState(() => _isOpeningActions = false);

    if (refreshed == null) {
      final message = widget.cubit.actionErrorMessage;
      if (message != null) {
        VToast.show(
          context,
          title: 'Không thể mở thao tác',
          message: message,
          type: VToastType.danger,
        );
      }
      return;
    }

    if (!mounted) return;
    await PriceRuleActionSheet.show(
      context: context,
      rule: refreshed,
      onEdit: () async {
        final updated = await context.push<CustomerPriceRuleDetailDto>(
          '/pricing/${refreshed.id}/edit',
          extra: refreshed,
        );
        if (updated != null && context.mounted) {
          widget.cubit.loadDetail(ruleId: refreshed.id);
        }
      },
      onDisable: () => PriceRuleDisableSheet.show(
        context: context,
        rule: refreshed,
        cubit: widget.cubit,
      ),
      onReenable: () {
        final currentRule = switch (widget.cubit.state) {
          PriceRuleDetailLoaded(:final rule) => rule,
          PriceRuleDetailActionSuccess(:final rule) => rule,
          _ => refreshed,
        };
        PriceRuleReenableSheet.show(
          context: context,
          rule: currentRule,
          cubit: widget.cubit,
        );
      },
      onHistory: () => context.push('/pricing/${refreshed.id}/history'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(VSpacing.space4),
        child: VButton(
          label: _isOpeningActions ? 'Đang tải...' : 'Thao tác',
          variant: VButtonVariant.primary,
          fullWidth: true,
          onPressed: _isOpeningActions ? null : _openActionSheet,
        ),
      ),
    );
  }
}
