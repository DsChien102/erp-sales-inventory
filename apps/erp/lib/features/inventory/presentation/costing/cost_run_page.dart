import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/logic/costing/cost_run_cubit.dart';
import 'package:erp/features/inventory/logic/costing/cost_run_state.dart';
import 'package:erp/features/inventory/logic/costing/costing_rules.dart';
import 'package:erp/features/inventory/presentation/costing/cost_run_blocks.dart';
import 'package:erp/features/inventory/presentation/costing/cost_run_detail_sheet.dart';
import 'package:erp/features/inventory/presentation/costing/cost_run_sheets.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

/// SCR-074: Chốt kỳ / Cập nhật giá vốn.
class CostRunPage extends StatelessWidget {
  const CostRunPage({
    super.key,
    this.runId,
    required this.kind,
    this.initialPeriod,
    this.onNavigate,
    this.onBack,
  });

  final String? runId;
  final CostRunKind kind;
  final DateTime? initialPeriod;
  final ValueChanged<String>? onNavigate;
  final VoidCallback? onBack;

  CostingRepository _resolveRepo(BuildContext context) {
    try {
      return context.read<CostingRepository>();
    } catch (_) {
      return getIt<CostingRepository>();
    }
  }

  DateTime _defaultPeriod() {
    if (initialPeriod != null) return initialPeriod!;
    final now = DateTime.now();
    if (kind == CostRunKind.periodClose) {
      return DateTime(now.year, now.month - 1, 1);
    }
    return DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) {
        final cubit = CostRunCubit(_resolveRepo(ctx));
        if (runId != null && runId!.isNotEmpty) {
          cubit.load(runId!);
        } else {
          cubit.startDraft(kind, _defaultPeriod());
        }
        return cubit;
      },
      child: _CostRunView(
        initialRunId: runId,
        onNavigate: onNavigate,
        onBack: onBack,
      ),
    );
  }
}

class _CostRunView extends StatelessWidget {
  const _CostRunView({
    this.initialRunId,
    this.onNavigate,
    this.onBack,
  });

  final String? initialRunId;
  final ValueChanged<String>? onNavigate;
  final VoidCallback? onBack;

  void _navigate(BuildContext context, String path, {bool replace = false}) {
    if (onNavigate != null) {
      onNavigate!(path);
      return;
    }
    if (replace) {
      context.replace(path);
    } else {
      context.go(path);
    }
  }

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    context.go('/warehouse/costing');
  }

  void _handleBlockerAction(
    BuildContext context,
    CostBlocker blocker,
    BlockerView view,
  ) {
    switch (view.action) {
      case CostBlockerAction.closePeriod:
        _navigate(context, '/warehouse/costing/new?kind=PERIOD_CLOSE');
      case CostBlockerAction.midPeriod:
        _navigate(context, '/warehouse/costing/new?kind=MID_PERIOD');
      case CostBlockerAction.stocktakes:
        _navigate(context, '/warehouse/stocktakes');
      case CostBlockerAction.openPendingRun:
        final pendingId = blocker.pendingRunId;
        if (pendingId != null && pendingId.isNotEmpty) {
          _navigate(context, '/warehouse/costing/runs/$pendingId');
        } else {
          _navigate(context, '/warehouse/costing');
        }
      case CostBlockerAction.none:
        break;
    }
  }

  String _titleFor(CostRunState state) {
    final run = state.run;
    if (run != null) return runTitle(run.kind, run.periodMonth);
    final period = state.period ?? DateTime.now();
    return runTitle(state.kind, period);
  }

  String? _subtitleFor(CostRunState state) {
    final run = state.run;
    if (run == null) return null;
    return runSubtitle(run);
  }

  Widget? _bottomBarFor(
    BuildContext context,
    CostRunCubit cubit,
    CostRunState state,
  ) {
    if (state.phase == CostRunPhase.draft) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space4,
          vertical: VSpacing.space3,
        ),
        child: InventoryFooter(
          actions: [
            InventoryFooterAction(
              label: 'Tính giá vốn',
              primary: true,
              onPressed: cubit.calculate,
            ),
          ],
        ),
      );
    }

    final run = state.run;
    if (state.phase != CostRunPhase.loaded || run == null) return null;

    if (run.status == CostRunStatus.blocked) {
      return _footerWithDiscard(
        context,
        cubit: cubit,
        primaryLabel: 'Tính lại',
        onPrimary: cubit.calculate,
      );
    }

    if (run.status == CostRunStatus.readyForReview) {
      return _footerWithDiscard(
        context,
        cubit: cubit,
        primaryLabel: 'Công bố giá vốn',
        onPrimary: () => showCostPublishSheet(
          context,
          run: run,
          onConfirm: cubit.publish,
        ),
      );
    }

    return null;
  }

  Widget _footerWithDiscard(
    BuildContext context, {
    required CostRunCubit cubit,
    required String primaryLabel,
    required VoidCallback onPrimary,
  }) {
    final isWide = inventoryIsWide(context);
    final discardButton = VButton(
      label: 'Bỏ lần tính',
      variant: VButtonVariant.tertiary,
      tone: VComponentTone.danger,
      onPressed: cubit.discard,
    );
    final primaryButton = VButton(
      label: primaryLabel,
      variant: VButtonVariant.primary,
      fullWidth: !isWide,
      onPressed: onPrimary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space3,
      ),
      child: isWide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                discardButton,
                const SizedBox(width: VSpacing.space3),
                primaryButton,
              ],
            )
          : Row(
              children: [
                discardButton,
                const SizedBox(width: VSpacing.space3),
                Expanded(child: primaryButton),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = inventoryIsWide(context);

    return BlocConsumer<CostRunCubit, CostRunState>(
      listener: (context, state) {
        if (state.phase == CostRunPhase.published && state.run != null) {
          _navigate(
            context,
            '/warehouse/costing/runs/${state.run!.runId}/result',
          );
          return;
        }
        if (state.phase == CostRunPhase.discarded) {
          _navigate(context, '/warehouse/costing');
          return;
        }
        if (state.phase == CostRunPhase.loaded &&
            state.run != null &&
            state.run!.runId != initialRunId) {
          _navigate(
            context,
            '/warehouse/costing/runs/${state.run!.runId}',
            replace: true,
          );
        }
        if (state.message != null &&
            state.message!.isNotEmpty &&
            state.phase == CostRunPhase.loaded &&
            state.run?.status != CostRunStatus.stale) {
          VToast.show(
            context,
            title: state.message!,
            message: '',
            type: VToastType.danger,
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<CostRunCubit>();

        return VPageScaffold(
          title: _titleFor(state),
          subtitle: _subtitleFor(state),
          contentMaxWidth: isWide
              ? VPageScaffold.fullWidth
              : VPageScaffold.defaultContentMaxWidth,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Quay về Giá vốn',
            onPressed: () => _handleBack(context),
          ),
          bottomBar: _bottomBarFor(context, cubit, state),
          body: _buildBody(context, cubit, state),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    CostRunCubit cubit,
    CostRunState state,
  ) {
    if (state.phase == CostRunPhase.calculating ||
        state.phase == CostRunPhase.publishing) {
      return Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const InventoryLoading(
              blocks: [
                InventorySkeletonBlock.heading,
                InventorySkeletonBlock.card,
                InventorySkeletonBlock.card,
              ],
            ),
            const SizedBox(height: VSpacing.space3),
            VText(
              'Có thể rời màn hình. Kết quả được lưu trong cùng lần tính.',
              variant: VTextVariant.bodySmall,
              color: context.vColors.textSecondary,
            ),
          ],
        ),
      );
    }

    if (state.phase == CostRunPhase.denied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: InventoryDenied(
            what: 'tính và công bố giá vốn',
            next: 'Chỉ chủ cửa hàng thực hiện việc này.',
            onExit: () => _handleBack(context),
          ),
        ),
      );
    }

    if (state.phase == CostRunPhase.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: InventoryEmpty(
            title: 'Không tải được lần tính giá vốn',
            description: state.message ?? 'Kiểm tra kết nối rồi thử lại.',
            actionLabel: 'Thử lại',
            onAction: () {
              if (initialRunId != null && initialRunId!.isNotEmpty) {
                cubit.load(initialRunId!);
              } else {
                cubit.calculate();
              }
            },
          ),
        ),
      );
    }

    if (state.phase == CostRunPhase.draft) {
      final period = state.period ?? DateTime.now();
      return SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            VKeyValueGroup(
              rows: [
                VKeyValueRow(
                  label: 'Kỳ',
                  value: periodLabel(period),
                  mono: true,
                ),
                const VKeyValueRow(
                  label: 'Phạm vi',
                  value: 'Toàn bộ sản phẩm',
                ),
              ],
            ),
            const SizedBox(height: VSpacing.space4),
            const CostMethodBlock(method: CostMethod.moving),
          ],
        ),
      );
    }

    final run = state.run;
    if (run == null) return const SizedBox.shrink();

    if (run.status == CostRunStatus.superseded) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: InventoryStale(
          title: 'Lần tính đã được thay',
          description:
              'Lần tính này đã bị bỏ hoặc thay bằng lần tính kế tiếp.',
          actionLabel: 'Về giá vốn',
          onAction: () => _handleBack(context),
        ),
      );
    }

    if (run.status == CostRunStatus.stale) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            InventoryStale(
              title: 'Dữ liệu đầu vào đã thay đổi',
              description:
                  'Kết quả cũ được giữ để truy vết nhưng không còn đủ điều kiện công bố.',
              actionLabel: 'Tạo lần tính kế tiếp',
              onAction: cubit.calculate,
            ),
            const SizedBox(height: VSpacing.space4),
            CostMethodBlock(method: run.method),
          ],
        ),
      );
    }

    if (run.status == CostRunStatus.blocked) {
      final blockers = run.blockers;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            blockers.isNotEmpty
                ? VBanner(
                    tone: VComponentTone.warning,
                    title: 'Chưa công bố được',
                    description:
                        'Xử lý ${blockers.length} việc dưới đây rồi tính lại.',
                  )
                : const VBanner(
                    tone: VComponentTone.info,
                    title: 'Đã xử lý hết việc chặn',
                    description: 'Tính lại để có kết quả mới.',
                  ),
            if (blockers.isNotEmpty) ...[
              const SizedBox(height: VSpacing.space3),
              CostBlockerList(
                blockers: blockers,
                onAction: (b, v) => _handleBlockerAction(context, b, v),
              ),
            ],
            const SizedBox(height: VSpacing.space4),
            CostMethodBlock(method: run.method),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: K7Split(
        wideMain: true,
        asideWebOnly: true,
        main: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            CostMetricCards(totals: run.totals),
            const SizedBox(height: VSpacing.space4),
            CostWritesBlock(totals: run.totals),
            const SizedBox(height: VSpacing.space4),
            CostProductsBlock(
              lines: run.lines,
              onViewAllProducts: () => showCostProductsSheet(
                context,
                lines: run.lines,
              ),
              onViewDetail: () => showCostRunDetailSheet(
                context,
                run: run,
              ),
            ),
            const SizedBox(height: VSpacing.space4),
            CostMethodBlock(
              method: run.method,
              altMethod: run.alt.method,
              onCompare: () => showCostCompareSheet(context, alt: run.alt),
            ),
          ],
        ),
        aside: CostSummaryGroup(run: run),
      ),
    );
  }
}
