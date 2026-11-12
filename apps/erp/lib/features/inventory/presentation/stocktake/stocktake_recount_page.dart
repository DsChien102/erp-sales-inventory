import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_count_state.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_recount_cubit.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_recount_state.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/patterns/k7_edit_cell.dart';
import 'package:erp/features/inventory/presentation/stocktake/widgets/stocktake_confirm_sheet.dart';
import 'package:erp/features/inventory/presentation/stocktake/widgets/stocktake_recount_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

/// SCR-045: Chênh lệch và đếm lại một vòng trước khi ghi nhận điều chỉnh tồn kho.
class StocktakeRecountPage extends StatelessWidget {
  const StocktakeRecountPage({
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
      create: (_) => StocktakeRecountCubit(
        repository: _resolveRepo(context),
        sessionId: sessionId,
      )..load(),
      child: _StocktakeRecountView(
        onNavigate: onNavigate,
        onBackToList: onBackToList,
      ),
    );
  }
}

class _StocktakeRecountView extends StatefulWidget {
  const _StocktakeRecountView({
    required this.onNavigate,
    required this.onBackToList,
  });

  final void Function(String id, StocktakeStatus status) onNavigate;
  final VoidCallback onBackToList;

  @override
  State<_StocktakeRecountView> createState() => _StocktakeRecountViewState();
}

class _StocktakeRecountViewState extends State<_StocktakeRecountView> {
  final Map<String, FocusNode> _focusNodes = {};

  FocusNode _focusNodeFor(String lineId) =>
      _focusNodes.putIfAbsent(lineId, () => FocusNode());

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();
    super.dispose();
  }

  void _focusNextUncounted(StocktakeRecountState state, String currentLineId) {
    final lines = state.varianceLines;
    final startIdx = lines.indexWhere((l) => l.lineId == currentLineId);
    final candidates = [
      if (startIdx >= 0) ...lines.skip(startIdx + 1),
      ...lines.take(startIdx >= 0 ? startIdx : lines.length),
    ];
    for (final line in candidates) {
      if (line.lineId == currentLineId) continue;
      if (parseStocktakeCount(state.inputs[line.lineId] ?? '') == null) {
        _focusNodeFor(line.lineId).requestFocus();
        return;
      }
    }
  }

  Future<void> _showMatchedSheet(
    BuildContext context,
    List<StocktakeLine> matchedLines,
  ) {
    return showVAdaptiveSheet<void>(
      context: context,
      title: 'Mặt hàng khớp',
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < matchedLines.length; i++) ...[
              VListRow(
                type: VListRowType.plain,
                title: matchedLines[i].lotCode != null
                    ? '${matchedLines[i].productName} · Lô ${matchedLines[i].lotCode}'
                    : matchedLines[i].productName,
                subtitle:
                    '${matchedLines[i].productCode} · Theo sổ ${formatStockQuantity(matchedLines[i].bookQty ?? 0, matchedLines[i].uom)} · Đếm được ${formatStockQuantity(matchedLines[i].firstQty ?? 0, matchedLines[i].uom)}',
                trailing: const VBadge(
                  label: 'Khớp',
                  tone: VComponentTone.success,
                ),
              ),
              if (i < matchedLines.length - 1)
                const SizedBox(height: VSpacing.space2),
            ],
            const SizedBox(height: VSpacing.space4),
            VButton(
              label: 'Đóng',
              variant: VButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSubmit(
    BuildContext context,
    StocktakeRecountCubit cubit,
  ) async {
    cubit.prepareSubmitKey();
    final confirmed = await showStocktakeConfirmSheet(
      context,
      title: 'Ghi nhận điều chỉnh?',
      description:
          'Kết quả đếm lại được lưu, không sửa được. Dòng còn lệch được điều chỉnh vào tồn kho theo số đếm.',
      confirmLabel: 'Ghi nhận',
    );
    if (confirmed == null || !mounted) return;
    await cubit.submitRecount();
  }

  Future<void> _confirmCancel(
    BuildContext context,
    StocktakeRecountCubit cubit,
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
    StocktakeRecountCubit cubit,
    StocktakeRecountState state,
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
        label: 'Theo sổ',
        numeric: true,
        cell: (line) => Text(
          formatStockQuantity(line.bookQty ?? 0, line.uom),
          style: VTypography.monoNumeric.copyWith(color: colors.textPrimary),
          textAlign: TextAlign.right,
        ),
      ),
      K7Column<StocktakeLine>(
        label: 'Đếm đầu',
        numeric: true,
        cell: (line) => Text(
          formatStockQuantity(line.firstQty ?? 0, line.uom),
          style: VTypography.monoNumeric.copyWith(color: colors.textPrimary),
          textAlign: TextAlign.right,
        ),
      ),
      K7Column<StocktakeLine>(
        label: 'Chênh lệch',
        numeric: true,
        cell: (line) => Align(
          alignment: Alignment.centerRight,
          child: VBadge(
            label: varianceLabel(line.variance ?? 0, line.uom),
            tone: VComponentTone.warning,
          ),
        ),
      ),
      K7Column<StocktakeLine>(
        label: 'Lý do',
        cell: (line) {
          final reason = state.reasons[line.lineId];
          if ((line.variance ?? 0) >= 0 || reason == null) {
            return Text(
              '—',
              style: VTypography.bodyDefault.copyWith(
                color: colors.textSecondary,
              ),
            );
          }
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 216),
            child: VSegmentedControl(
              segments: stocktakeLossReasonLabels,
              selectedIndex: reason.index,
              onChanged: (idx) => cubit.setReason(
                line.lineId,
                StocktakeLossReason.values[idx],
              ),
            ),
          );
        },
      ),
      K7Column<StocktakeLine>(
        label: 'Đếm lại',
        numeric: true,
        cell: (line) => Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
              K7EditCell(
                value: state.inputs[line.lineId] ?? '',
                unit: line.uom,
                allowDecimal: true,
                maxWidth: 84,
                textInputAction: TextInputAction.next,
                focusNode: _focusNodeFor(line.lineId),
                semanticLabel: 'Số lượng đếm lại — ${line.productName}',
                onChanged: (v) => cubit.setCount(line.lineId, v),
                onSubmitted: (_) => _focusNextUncounted(state, line.lineId),
              ),
            const SizedBox(width: VSpacing.space2),
            Flexible(
              child: VButton(
                label: 'Vẫn ${formatStockQuantity(line.firstQty ?? 0, line.uom)}',
                variant: VButtonVariant.secondary,
                size: VButtonSize.small,
                onPressed: () {
                  cubit.applySameAsFirst(line);
                  _focusNextUncounted(state, line.lineId);
                },
              ),
            ),
          ],
        ),
      ),
    ];
  }

  static const Map<int, TableColumnWidth> _webColumnWidths = {
    0: FlexColumnWidth(1.3),
    1: FlexColumnWidth(0.9),
    2: IntrinsicColumnWidth(),
    3: IntrinsicColumnWidth(),
    4: IntrinsicColumnWidth(),
    5: FixedColumnWidth(232),
    6: FixedColumnWidth(236),
  };

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<StocktakeRecountCubit>();
    final state = cubit.state;
    final colors = context.vColors;
    final isWide = inventoryIsWide(context);
    final session = state.session;
    final hasStateChange = state.stateChangeKind != null;
    final canShowFooter =
        state.status == StocktakeRecountStatus.ready ||
        state.status == StocktakeRecountStatus.submitting;
    final showNormalFooter =
        canShowFooter && session != null && !hasStateChange;

    return BlocListener<StocktakeRecountCubit, StocktakeRecountState>(
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
        title: 'Chênh lệch và đếm lại',
        subtitle: session != null ? '${session.code} · Đếm lại lần 1' : null,
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
            ? _RecountBottomBar(
                isWide: isWide,
                missing: state.missingCount,
                submitError: state.submitError,
                onSubmit: state.missingCount == 0 &&
                        state.status != StocktakeRecountStatus.submitting
                    ? () => _confirmSubmit(context, cubit)
                    : null,
              )
            : null,
        body: Builder(
          builder: (context) {
            if (state.status == StocktakeRecountStatus.loading) {
              return const Padding(
                padding: EdgeInsets.all(VSpacing.space4),
                child: InventoryLoading(
                  blocks: [
                    InventorySkeletonBlock.text,
                    InventorySkeletonBlock.card,
                    InventorySkeletonBlock.row,
                    InventorySkeletonBlock.row,
                  ],
                ),
              );
            }

            if (state.status == StocktakeRecountStatus.loadError ||
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
                  description:
                      'Phiên đã bị hủy hoặc đã mở khóa. Số đã đếm vẫn được lưu.',
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

            final varianceLines = state.varianceLines;
            final matchedLines = state.matchedLines;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Kết quả vòng trước được giữ nguyên trong lịch sử.',
                    style: VTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: VSpacing.space3),
                  VSummaryStrip(
                    items: [
                      VSummaryItem(
                        'Mặt hàng lệch',
                        '${varianceLines.length}',
                      ),
                      VSummaryItem(
                        'Khớp',
                        '${matchedLines.length}',
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpacing.space4),
                  if (isWide)
                    K7Table<StocktakeLine>(
                      columns: _webColumns(context, cubit, state),
                      rows: varianceLines,
                      columnWidths: _webColumnWidths,
                      mobileRow: (line) => _buildMobileCard(
                        cubit,
                        state,
                        line,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < varianceLines.length; i++) ...[
                          _buildMobileCard(cubit, state, varianceLines[i]),
                          if (i < varianceLines.length - 1)
                            const SizedBox(height: VSpacing.space3),
                        ],
                      ],
                    ),
                  if (matchedLines.isNotEmpty) ...[
                    const SizedBox(height: VSpacing.space3),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: VButton(
                        label: 'Xem ${matchedLines.length} mặt hàng khớp',
                        variant: VButtonVariant.tertiary,
                        onPressed: () =>
                            _showMatchedSheet(context, matchedLines),
                      ),
                    ),
                  ],
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

  Widget _buildMobileCard(
    StocktakeRecountCubit cubit,
    StocktakeRecountState state,
    StocktakeLine line,
  ) {
    return StocktakeRecountCard(
      line: line,
      value: state.inputs[line.lineId] ?? '',
      focusNode: _focusNodeFor(line.lineId),
      reason: state.reasons[line.lineId],
      onChanged: (v) => cubit.setCount(line.lineId, v),
      onSubmitted: (_) => _focusNextUncounted(state, line.lineId),
      onApplySame: () {
        cubit.applySameAsFirst(line);
        _focusNextUncounted(state, line.lineId);
      },
      onReasonChanged: (r) => cubit.setReason(line.lineId, r),
    );
  }
}

class _RecountBottomBar extends StatelessWidget {
  const _RecountBottomBar({
    required this.isWide,
    required this.missing,
    this.submitError,
    required this.onSubmit,
  });

  final bool isWide;
  final int missing;
  final String? submitError;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final blocker = recountBlocker(missing) ?? '';

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
                  label: 'Ghi nhận điều chỉnh',
                  variant: VButtonVariant.primary,
                  onPressed: onSubmit,
                ),
              ],
            )
          else
            InventoryReasonFooter(
              label: 'Ghi nhận điều chỉnh',
              reason: blocker,
              onPressed: onSubmit,
            ),
        ],
      ),
    );
  }
}
