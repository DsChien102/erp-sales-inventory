import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_create_cubit.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_create_state.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/stocktake/widgets/stocktake_confirm_sheet.dart';
import 'package:erp/features/inventory/presentation/stocktake/widgets/stocktake_scope_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

/// SCR-043: Tạo phiên kiểm kê mới.
class StocktakeCreatePage extends StatelessWidget {
  const StocktakeCreatePage({
    super.key,
    this.initialProductId,
    this.initialLotId,
    required this.onOpened,
    required this.onOpenConflict,
    this.onBack,
  });

  final String? initialProductId;
  final String? initialLotId;
  final ValueChanged<String> onOpened;
  final void Function(String id, StocktakeStatus status) onOpenConflict;
  final VoidCallback? onBack;

  StocktakeRepository _resolveRepo(BuildContext context) {
    try {
      return context.read<StocktakeRepository>();
    } catch (_) {
      return getIt<StocktakeRepository>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StocktakeCreateCubit(
        repository: _resolveRepo(context),
        initialProductId: initialProductId,
        initialLotId: initialLotId,
      )..load(),
      child: _StocktakeCreateView(
        onOpened: onOpened,
        onOpenConflict: onOpenConflict,
        onBack: onBack,
      ),
    );
  }
}

class _StocktakeCreateView extends StatefulWidget {
  const _StocktakeCreateView({
    required this.onOpened,
    required this.onOpenConflict,
    this.onBack,
  });

  final ValueChanged<String> onOpened;
  final void Function(String id, StocktakeStatus status) onOpenConflict;
  final VoidCallback? onBack;

  @override
  State<_StocktakeCreateView> createState() => _StocktakeCreateViewState();
}

class _StocktakeCreateViewState extends State<_StocktakeCreateView> {
  final TextEditingController _reasonController = TextEditingController(
    text: 'Kiểm kê định kỳ',
  );

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickScope(
    BuildContext context,
    StocktakeCreateCubit cubit,
    StocktakeCreateState state,
  ) async {
    final opts = state.options;
    if (opts == null) return;
    final picked = await showStocktakeScopeSheet(
      context,
      kind: state.scopeKind,
      products: opts.products,
      lots: opts.lots,
      selectedId: state.scopeKind == StocktakeScopeKind.lot
          ? state.selectedLotId
          : state.selectedProductId,
    );
    if (picked == null || !mounted) return;
    if (state.scopeKind == StocktakeScopeKind.lot) {
      cubit.selectLot(picked);
    } else {
      cubit.selectProduct(picked);
    }
  }

  Future<void> _confirmAndOpen(
    BuildContext context,
    StocktakeCreateCubit cubit,
    StocktakeCreateState state,
  ) async {
    cubit.prepareOpenKey();
    final confirmed = await showStocktakeConfirmSheet(
      context,
      title: 'Mở phiên kiểm kê?',
      description:
          'Phiên sẽ đếm ${state.scopeLineCount} mặt hàng. Hàng vẫn bán, nhận bình thường trong lúc kiểm.',
      confirmLabel: 'Mở phiên',
    );
    if (confirmed == null || !mounted) return;
    await cubit.submitOpen();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<StocktakeCreateCubit>();
    final state = cubit.state;
    final isWide = inventoryIsWide(context);
    final canShowFooter = state.status == StocktakeCreateStatus.ready ||
        state.status == StocktakeCreateStatus.submitting;
    final blocker = state.blocker;
    final isBusy = state.status == StocktakeCreateStatus.submitting;

    return BlocListener<StocktakeCreateCubit, StocktakeCreateState>(
      listenWhen: (prev, curr) =>
          prev.openedSessionId != curr.openedSessionId &&
          curr.openedSessionId != null,
      listener: (_, s) {
        final id = s.openedSessionId;
        if (id != null) {
          widget.onOpened(id);
        }
      },
      child: VPageScaffold(
        title: 'Tạo phiên kiểm kê',
        contentMaxWidth: isWide
            ? VPageScaffold.fullWidth
            : VPageScaffold.defaultContentMaxWidth,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
        bottomBar: canShowFooter
            ? _CreateBottomBar(
                isWide: isWide,
                blocker: blocker,
                submitError: state.submitError,
                isScopeEmptyError: state.isScopeEmptyError,
                isBusy: isBusy,
                onRetry: cubit.submitOpen,
                onSubmit: blocker == null && !isBusy
                    ? () => _confirmAndOpen(context, cubit, state)
                    : null,
              )
            : null,
        body: Builder(
          builder: (context) {
            if (state.status == StocktakeCreateStatus.loading) {
              return const Padding(
                padding: EdgeInsets.all(VSpacing.space4),
                child: InventoryLoading(
                  blocks: [
                    InventorySkeletonBlock.card,
                    InventorySkeletonBlock.row,
                    InventorySkeletonBlock.row,
                  ],
                ),
              );
            }

            if (state.status == StocktakeCreateStatus.loadError ||
                state.options == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: InventoryEmpty(
                    title: 'Không tải được dữ liệu kiểm kê',
                    description: 'Kiểm tra kết nối rồi thử lại.',
                    actionLabel: 'Thử lại',
                    onAction: cubit.load,
                  ),
                ),
              );
            }

            final mainForm = _CreateMainForm(
              state: state,
              reasonController: _reasonController,
              onScopeChanged: cubit.setScopeKind,
              onPickScope: () => _pickScope(context, cubit, state),
              onCounterChanged: cubit.setCounter,
              onReasonChanged: cubit.setReason,
              onOpenConflict: widget.onOpenConflict,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: K7Split(
                main: mainForm,
                aside: _CreateSummaryAside(state: state),
                asideWebOnly: true,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CreateMainForm extends StatelessWidget {
  const _CreateMainForm({
    required this.state,
    required this.reasonController,
    required this.onScopeChanged,
    required this.onPickScope,
    required this.onCounterChanged,
    required this.onReasonChanged,
    required this.onOpenConflict,
  });

  final StocktakeCreateState state;
  final TextEditingController reasonController;
  final ValueChanged<StocktakeScopeKind> onScopeChanged;
  final VoidCallback onPickScope;
  final ValueChanged<String> onCounterChanged;
  final ValueChanged<String> onReasonChanged;
  final void Function(String id, StocktakeStatus status) onOpenConflict;

  @override
  Widget build(BuildContext context) {
    final opts = state.options!;
    final conflict = state.conflict;
    final showReasonError = state.reason.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (conflict != null) ...[
          InventoryStale(
            title: 'Phạm vi đang có phiên khác',
            description:
                '${conflict.code} đang kiểm ${conflict.scopeLabel}. Mở phiên đó hoặc chọn phạm vi khác.',
            actionLabel: 'Mở phiên đang kiểm',
            onAction: () =>
                onOpenConflict(conflict.sessionId, StocktakeStatus.counting),
          ),
          const SizedBox(height: VSpacing.space4),
        ],
        VField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const VFieldLabel('Phạm vi'),
              const SizedBox(height: VSpacing.space2),
              VChoiceList<StocktakeScopeKind>(
                selected: [state.scopeKind],
                choices: [
                  VChoiceOption(
                    value: StocktakeScopeKind.all,
                    label: 'Toàn kho',
                    helpText: '${opts.allCount} mặt hàng',
                  ),
                  VChoiceOption(
                    value: StocktakeScopeKind.product,
                    label: 'Sản phẩm',
                    helpText: state.scopeKind == StocktakeScopeKind.product &&
                            state.selectedProduct != null
                        ? '${state.selectedProduct!.lineCount} mặt hàng'
                        : null,
                  ),
                  VChoiceOption(
                    value: StocktakeScopeKind.lot,
                    label: 'Lô',
                    helpText: state.scopeKind == StocktakeScopeKind.lot &&
                            state.selectedLot != null
                        ? '1 mặt hàng'
                        : null,
                  ),
                ],
                onChanged: (selected) {
                  if (selected.isNotEmpty) {
                    onScopeChanged(selected.last);
                  }
                },
              ),
            ],
          ),
        ),
        if (state.scopeKind != StocktakeScopeKind.all) ...[
          const SizedBox(height: VSpacing.space2),
          _ScopePickButton(
            targetName: state.scopeDisplayName,
            onPressed: onPickScope,
          ),
        ],
        const SizedBox(height: VSpacing.space4),
        VField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const VFieldLabel('Người đếm'),
              const SizedBox(height: VSpacing.space2),
              VSelect<String>(
                value: state.counterUserId.isEmpty ? null : state.counterUserId,
                items: [
                  for (final m in opts.members)
                    DropdownMenuItem<String>(
                      value: m.userId,
                      child: Text(m.name),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) onCounterChanged(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space4),
        VField(
          invalid: showReasonError,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const VFieldLabel('Lý do kiểm kê'),
              const SizedBox(height: VSpacing.space2),
              VTextField(
                controller: reasonController,
                hintText: 'Nhập lý do kiểm kê',
                onChanged: onReasonChanged,
              ),
              if (showReasonError) ...[
                const SizedBox(height: VSpacing.space1),
                const VFieldError('Nhập lý do kiểm kê'),
              ],
            ],
          ),
        ),
        if (state.isScopeKnown) ...[
          const SizedBox(height: VSpacing.space4),
          VBanner(
            tone: VComponentTone.info,
            title: 'Khi mở phiên',
            description:
                '${state.scopeLineCount} mặt hàng sẽ được đếm.\n'
                'Hàng vẫn bán, nhận bình thường; chênh lệch tính theo tồn lúc ghi nhận.',
          ),
        ],
      ],
    );
  }
}

class _ScopePickButton extends StatelessWidget {
  const _ScopePickButton({
    this.targetName,
    required this.onPressed,
  });

  final String? targetName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Semantics(
      button: true,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(VRadius.card),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space3,
              vertical: VSpacing.space2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(VRadius.card),
              border: VBorders.all(colors.borderDefault),
            ),
            child: targetName == null
                ? Center(
                    child: VText(
                      'Chọn phạm vi cụ thể',
                      variant: VTextVariant.bodyDefault,
                      color: colors.textPrimary,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: VText(
                          targetName!,
                          variant: VTextVariant.bodyDefault,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: VSpacing.space2),
                      VText(
                        'Đổi',
                        variant: VTextVariant.bodyDefault,
                        color: colors.textBrand,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _CreateSummaryAside extends StatelessWidget {
  const _CreateSummaryAside({required this.state});

  final StocktakeCreateState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final items = state.previewItems;
    final shown = items.take(8).toList(growable: false);
    final extra = items.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        VKeyValueGroup(
          title: 'Tóm tắt',
          rows: [
            VKeyValueRow(
              label: 'Phạm vi',
              value: state.scopeDisplayName ?? '—',
            ),
            VKeyValueRow(
              label: 'Người đếm',
              value: state.counterName ?? '—',
            ),
          ],
        ),
        if (state.isScopeKnown && shown.isNotEmpty) ...[
          const SizedBox(height: VSpacing.space4),
          VText(
            'Mặt hàng trong phạm vi',
            variant: VTextVariant.headingH4,
            color: colors.textPrimary,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: VSpacing.space2),
          for (final item in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.space1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    '•  ',
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                  Expanded(
                    child: VText(
                      item,
                      variant: VTextVariant.bodySmall,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          if (extra > 0)
            VText(
              'và $extra mặt hàng khác',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
        ],
      ],
    );
  }
}

class _CreateBottomBar extends StatelessWidget {
  const _CreateBottomBar({
    required this.isWide,
    required this.blocker,
    required this.submitError,
    required this.isScopeEmptyError,
    required this.isBusy,
    required this.onRetry,
    required this.onSubmit,
  });

  final bool isWide;
  final String? blocker;
  final String? submitError;
  final bool isScopeEmptyError;
  final bool isBusy;
  final VoidCallback onRetry;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (submitError != null) ...[
            VBanner(
              tone: VComponentTone.warning,
              title: isScopeEmptyError ? submitError! : 'Không mở được phiên',
              description: isScopeEmptyError ? null : submitError!,
              footer: isScopeEmptyError
                  ? null
                  : VButton(
                      label: 'Thử lại',
                      variant: VButtonVariant.secondary,
                      size: VButtonSize.small,
                      onPressed: isBusy ? null : onRetry,
                    ),
            ),
            const SizedBox(height: VSpacing.space3),
          ],
          if (isWide)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (blocker != null && blocker!.isNotEmpty) ...[
                  Text(
                    blocker!,
                    style: VTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: VSpacing.space3),
                ],
                VButton(
                  label: 'Mở phiên kiểm kê',
                  variant: VButtonVariant.primary,
                  onPressed: onSubmit,
                ),
              ],
            )
          else
            InventoryReasonFooter(
              label: 'Mở phiên kiểm kê',
              reason: blocker ?? '',
              onPressed: onSubmit,
            ),
        ],
      ),
    );
  }
}
