import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_count_cubit.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_count_state.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/patterns/k7_edit_cell.dart';
import 'package:erp/features/inventory/presentation/stocktake/widgets/stocktake_confirm_sheet.dart';
import 'package:erp/features/inventory/presentation/stocktake/widgets/stocktake_line_card.dart';
import 'package:erp/features/inventory/presentation/stocktake/widgets/stocktake_unexpected_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

/// SCR-044: Đếm mù lần đầu; không hiển thị số theo sổ ở bất kỳ nhánh widget nào.
class StocktakeCountPage extends StatelessWidget {
  const StocktakeCountPage({
    super.key,
    required this.sessionId,
    required this.onNavigate,
    required this.onBackToList,
  });

  final String sessionId;
  final void Function(String id, StocktakeStatus status) onNavigate;
  final VoidCallback onBackToList;

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
      create: (_) => StocktakeCountCubit(
        repository: _resolveRepo(context),
        sessionId: sessionId,
      )..load(),
      child: _StocktakeCountView(
        onNavigate: onNavigate,
        onBackToList: onBackToList,
      ),
    );
  }
}

class _StocktakeCountView extends StatefulWidget {
  const _StocktakeCountView({
    required this.onNavigate,
    required this.onBackToList,
  });

  final void Function(String id, StocktakeStatus status) onNavigate;
  final VoidCallback onBackToList;

  @override
  State<_StocktakeCountView> createState() => _StocktakeCountViewState();
}

class _StocktakeCountViewState extends State<_StocktakeCountView> {
  final Map<String, FocusNode> _focusNodes = {};
  final TextEditingController _searchController = TextEditingController();

  FocusNode _focusNodeFor(String lineId) =>
      _focusNodes.putIfAbsent(lineId, () => FocusNode());

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();
    _searchController.dispose();
    super.dispose();
  }

  void _focusNextUncounted(StocktakeCountState state, String currentLineId) {
    final visible = state.visibleLines;
    final startIdx = visible.indexWhere((l) => l.lineId == currentLineId);
    final candidates = [
      if (startIdx >= 0) ...visible.skip(startIdx + 1),
      ...visible.take(startIdx >= 0 ? startIdx : visible.length),
    ];
    for (final line in candidates) {
      if (line.lineId == currentLineId) continue;
      if (parseStocktakeCount(state.inputs[line.lineId] ?? '') == null) {
        _focusNodeFor(line.lineId).requestFocus();
        return;
      }
    }
  }

  Future<void> _confirmSubmit(
    BuildContext context,
    StocktakeCountCubit cubit,
  ) async {
    cubit.prepareSubmitKey();
    final confirmed = await showStocktakeConfirmSheet(
      context,
      title: 'Nộp lần đếm đầu?',
      description:
          'Sau khi nộp, số sổ và chênh lệch mới được hiển thị. Không sửa được lần đếm này.',
      confirmLabel: 'Nộp kết quả',
    );
    if (confirmed == null || !mounted) return;
    await cubit.submitFirst();
  }

  Future<void> _confirmCancel(
    BuildContext context,
    StocktakeCountCubit cubit,
  ) async {
    final reason = await showStocktakeConfirmSheet(
      context,
      title: 'Hủy phiên kiểm kê?',
      description: 'Không tạo điều chỉnh; toàn bộ lịch sử đếm được giữ.',
      withReason: true,
      reasonLabel: 'Lý do',
      reasonHint: 'Bắt buộc để lưu lịch sử quyết định.',
      confirmLabel: 'Hủy phiên',
      danger: true,
    );
    if (reason == null || !mounted) return;
    await cubit.cancel(reason);
  }

  List<K7Column<StocktakeLine>> _webColumns(
    BuildContext context,
    StocktakeCountCubit cubit,
    StocktakeCountState state,
  ) {
    final colors = context.vColors;
    return [
      K7Column<StocktakeLine>(
        label: 'Sản phẩm',
        cell: (line) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            VText(
              line.productName,
              variant: VTextVariant.bodyDefault,
              color: colors.textPrimary,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            VText(
              line.productCode,
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
            if (line.isUnexpected) ...[
              const SizedBox(height: VSpacing.space1),
              const VBadge(
                label: 'Hàng thực tế',
                tone: VComponentTone.info,
              ),
            ],
          ],
        ),
      ),
      K7Column<StocktakeLine>(
        label: 'Lô',
        cell: (line) => VText(
          line.lotCode != null ? 'Lô ${line.lotCode}' : 'Không theo lô',
          variant: VTextVariant.bodyDefault,
          color: colors.textPrimary,
        ),
      ),
      K7Column<StocktakeLine>(
        label: 'Tình trạng',
        cell: (line) => VText(
          line.isExpired ? 'Hết hạn' : 'Bán được',
          variant: VTextVariant.bodyDefault,
          color: colors.textPrimary,
        ),
      ),
      K7Column<StocktakeLine>(
        label: 'Đếm được',
        numeric: true,
        cell: (line) => K7EditCell(
          value: state.inputs[line.lineId] ?? '',
          unit: line.uom,
          allowDecimal: true,
          maxWidth: 140,
          textInputAction: TextInputAction.next,
          focusNode: _focusNodeFor(line.lineId),
          semanticLabel: 'Số lượng thực tế — ${line.productName}',
          onChanged: (v) => cubit.setCount(line.lineId, v),
          onSubmitted: (_) => _focusNextUncounted(state, line.lineId),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<StocktakeCountCubit>();
    final state = cubit.state;
    final colors = context.vColors;
    final isWide = inventoryIsWide(context);
    final session = state.session;
    final hasStateChange = state.stateChangeKind != null;
    final canShowFooter =
        state.status == StocktakeCountStatus.ready ||
        state.status == StocktakeCountStatus.submitting;
    final showNormalFooter =
        canShowFooter && session != null && !hasStateChange;

    final subtitle = session != null
        ? '${session.code} · ${session.scopeLabel} · ${session.counterName}'
        : null;

    return BlocListener<StocktakeCountCubit, StocktakeCountState>(
      listenWhen: (prev, curr) =>
          prev.navigatedStatus != curr.navigatedStatus &&
          curr.navigatedStatus != null,
      listener: (_, s) {
        final target = s.navigatedStatus;
        final sId = s.session?.id;
        if (target != null && sId != null) {
          widget.onNavigate(sId, target);
        }
      },
      child: VPageScaffold(
        title: 'Đếm mù',
        subtitle: subtitle,
        contentMaxWidth: isWide
            ? VPageScaffold.fullWidth
            : VPageScaffold.defaultContentMaxWidth,
        leading: hasStateChange
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBackToList,
              ),
        bottomBar: showNormalFooter
            ? _CountBottomBar(
                isWide: isWide,
                uncounted: state.uncountedCount,
                submitError: state.submitError,
                isBusy: state.status == StocktakeCountStatus.submitting,
                onSubmit: state.uncountedCount == 0 &&
                        state.status != StocktakeCountStatus.submitting
                    ? () => _confirmSubmit(context, cubit)
                    : null,
              )
            : null,
        body: Builder(
          builder: (context) {
            if (state.status == StocktakeCountStatus.loading) {
              return const Padding(
                padding: EdgeInsets.all(VSpacing.space4),
                child: InventoryLoading(
                  blocks: [
                    InventorySkeletonBlock.text,
                    InventorySkeletonBlock.search,
                    InventorySkeletonBlock.row,
                    InventorySkeletonBlock.row,
                  ],
                ),
              );
            }

            if (state.status == StocktakeCountStatus.loadError ||
                session == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: InventoryEmpty(
                    title: 'Không tải được phiên kiểm kê',
                    description: 'Kiểm tra kết nối rồi thử lại.',
                    actionLabel: 'Thử lại',
                    onAction: cubit.load,
                  ),
                ),
              );
            }

            if (state.stateChangeKind == StocktakeStateChangeKind.lockLost) {
              return Padding(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: InventoryStale(
                  title: 'Phiên không còn hiệu lực',
                  description: 'Phiên đã bị hủy. Số đã đếm vẫn được lưu.',
                  actionLabel: 'Về kiểm kê',
                  onAction: widget.onBackToList,
                ),
              );
            }

            if (state.stateChangeKind == StocktakeStateChangeKind.conflict) {
              return Padding(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: InventoryStale(
                  title: 'Người khác vừa nộp phiên này',
                  description: 'Tải lại để xem bước hiện hành của phiên.',
                  actionLabel: 'Tải lại',
                  onAction: () => widget.onNavigate(
                    session.id,
                    state.stateChangeStatus ?? session.status,
                  ),
                ),
              );
            }

            final total = state.totalCount;
            final counted = state.countedCount;
            final visible = state.visibleLines;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Số lượng theo sổ chỉ xuất hiện sau khi nộp lần đếm đầu.',
                    style: VTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: VSpacing.space3),
                  VProgress(
                    value: total == 0 ? 0.0 : (counted / total).clamp(0.0, 1.0),
                    semanticLabel: 'Tiến độ đếm',
                  ),
                  const SizedBox(height: VSpacing.space1),
                  Text(
                    'Đã đếm $counted/$total mặt hàng',
                    style: VTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: VSpacing.space4),
                  VSearchBar(
                    controller: _searchController,
                    hintText: 'Tìm hoặc quét sản phẩm trong phạm vi',
                    onChanged: cubit.setQuery,
                  ),
                  const SizedBox(height: VSpacing.space3),
                  K7FilterChips(
                    items: [
                      K7Filter(
                        key: StocktakeCountFilter.todo.key,
                        label: StocktakeCountFilter.todo.label,
                        count: state.uncountedCount,
                      ),
                      K7Filter(
                        key: StocktakeCountFilter.done.key,
                        label: StocktakeCountFilter.done.label,
                        count: counted,
                      ),
                      K7Filter(
                        key: StocktakeCountFilter.all.key,
                        label: StocktakeCountFilter.all.label,
                        count: total,
                      ),
                    ],
                    selected: state.filter.key,
                    onSelected: (k) =>
                        cubit.setFilter(StocktakeCountFilter.fromKey(k)),
                  ),
                  const SizedBox(height: VSpacing.space3),
                  if (visible.isEmpty && session.lines.isNotEmpty)
                    state.filter == StocktakeCountFilter.todo &&
                            state.query.trim().isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: VSpacing.space3,
                            ),
                            child: Text(
                              'Đã đếm hết các mặt hàng.',
                              style: VTypography.bodySmall.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          )
                        : const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: VSpacing.space4,
                            ),
                            child: InventoryEmpty(
                              title: 'Không tìm thấy sản phẩm',
                              description: 'Thử mã, tên hoặc bộ lọc khác.',
                            ),
                          )
                  else if (isWide)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: K7Table<StocktakeLine>(
                          columns: _webColumns(context, cubit, state),
                          rows: visible,
                          mobileRow: (line) => StocktakeLineCard(
                            line: line,
                            value: state.inputs[line.lineId] ?? '',
                            focusNode: _focusNodeFor(line.lineId),
                            onChanged: (v) => cubit.setCount(line.lineId, v),
                            onSubmitted: (_) =>
                                _focusNextUncounted(state, line.lineId),
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < visible.length; i++) ...[
                          StocktakeLineCard(
                            line: visible[i],
                            value: state.inputs[visible[i].lineId] ?? '',
                            focusNode: _focusNodeFor(visible[i].lineId),
                            onChanged: (v) =>
                                cubit.setCount(visible[i].lineId, v),
                            onSubmitted: (_) =>
                                _focusNextUncounted(state, visible[i].lineId),
                          ),
                          if (i < visible.length - 1)
                            const SizedBox(height: VSpacing.space3),
                        ],
                      ],
                    ),
                  const SizedBox(height: VSpacing.space4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: VButton(
                      label: 'Thêm hàng thực tế',
                      variant: VButtonVariant.secondary,
                      onPressed: () => showStocktakeUnexpectedSheet(
                        context,
                        cubit: cubit,
                      ),
                    ),
                  ),
                  const SizedBox(height: VSpacing.space2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: VButton(
                        label: 'Hủy phiên',
                        variant: VButtonVariant.tertiary,
                        tone: VComponentTone.danger,
                        onPressed: () => _confirmCancel(context, cubit),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CountBottomBar extends StatelessWidget {
  const _CountBottomBar({
    required this.isWide,
    required this.uncounted,
    this.submitError,
    required this.isBusy,
    required this.onSubmit,
  });

  final bool isWide;
  final int uncounted;
  final String? submitError;
  final bool isBusy;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final blocker = firstCountBlocker(uncounted) ?? '';

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
              title: submitError!,
            ),
            const SizedBox(height: VSpacing.space3),
          ],
          if (isWide)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (blocker.isNotEmpty) ...[
                  Text(
                    blocker,
                    style: VTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: VSpacing.space3),
                ],
                VButton(
                  label: 'Nộp kết quả đếm',
                  variant: VButtonVariant.primary,
                  onPressed: onSubmit,
                ),
              ],
            )
          else
            InventoryReasonFooter(
              label: 'Nộp kết quả đếm',
              reason: blocker,
              onPressed: onSubmit,
            ),
        ],
      ),
    );
  }
}

