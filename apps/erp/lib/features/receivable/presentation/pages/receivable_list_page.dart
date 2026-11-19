import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/receivable_models.dart';
import '../../logic/receivable_format.dart';
import '../../logic/receivable_list_cubit.dart';
import '../../logic/receivable_list_state.dart';
import '../widgets/receivable_parts.dart';

/// CN-01 — danh sách khách còn nợ, quá hạn dẫn đầu.
class ReceivableListPage extends StatefulWidget {
  const ReceivableListPage({super.key, required this.cubit, this.selectedId, this.today});

  final ReceivableListCubit cubit;
  final String? selectedId;

  /// Chỉ cho test / golden; mặc định ngày hôm nay của máy.
  final DateTime? today;

  @override
  State<ReceivableListPage> createState() => _ReceivableListPageState();
}

class _ReceivableListPageState extends State<ReceivableListPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        widget.cubit.loadMore();
      }
    });
    _search.text = widget.cubit.state.query;
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    widget.cubit.clearQuery();
  }

  void _open(String customerId) {
    if (VListDetailLayout.isSplitOf(context)) {
      context.go('/more/receivables/$customerId');
    } else {
      context.push('/more/receivables/$customerId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final split = VListDetailLayout.isSplitOf(context);
    final today = widget.today ?? DateTime.now();
    return BlocProvider.value(
      value: widget.cubit,
      child: Scaffold(
        backgroundColor: context.vColors.surface,
        appBar: VAppBar(title: 'Công nợ phải thu', showBackButton: !split),
        body: BlocBuilder<ReceivableListCubit, ReceivableListState>(
          builder: (context, state) => switch (state.status) {
            ReceivableListStatus.loading => const _Loading(),
            ReceivableListStatus.error => ReceivableEmpty(
              title: 'Không tải được công nợ',
              actionLabel: 'Thử lại',
              onAction: widget.cubit.load,
              icon: VIcons.warning,
            ),
            ReceivableListStatus.ready => _buildReady(context, state, today),
          },
        ),
      ),
    );
  }

  Widget _buildReady(BuildContext context, ReceivableListState state, DateTime today) {
    final summary = state.summary!;
    if (summary.customerCount == 0 && state.items.isEmpty && state.query.isEmpty) {
      return const ReceivableEmpty(
        title: 'Không có khách nào đang nợ',
        description: 'Đơn bán nợ sẽ hiện ở đây.',
      );
    }
    final colors = context.vColors;
    final overdueOnly = state.filter == ReceivableFilter.overdue;
    final showCount = overdueOnly && state.query.isEmpty;
    return ListView(
      controller: _scroll,
      padding: EdgeInsets.zero,
      children: [
        _Hero(
          summary: summary,
          active: overdueOnly,
          onTap: widget.cubit.toggleOverdue,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            VSpacing.space3,
            VSpacing.space4,
            VSpacing.space2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tổng còn phải thu',
                style: VTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatVnd(summary.totalOutstandingMinor),
                    style: receivableMoneyStyle(context),
                  ),
                  Text(
                    '${summary.customerCount} khách',
                    style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(VSpacing.space4, 0, VSpacing.space4, VSpacing.space3),
          child: VSearchBar(
            hintText: 'Tìm tên, SĐT',
            semanticLabel: 'Tìm tên, SĐT',
            controller: _search,
            onChanged: widget.cubit.setQuery,
            suffix: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _search,
              builder: (context, value, _) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : SizedBox.square(
                      dimension: VSpacing.minTouchTarget,
                      child: IconButton(
                        tooltip: 'Xoá tìm kiếm',
                        onPressed: _clearSearch,
                        icon: VIcon(icon: VIcons.close, size: 16, color: colors.textMuted),
                      ),
                    ),
            ),
          ),
        ),
        if (state.items.isEmpty)
          SizedBox(
            height: 280,
            child: ReceivableEmpty(
              title: 'Không tìm thấy khách phù hợp.',
              actionLabel: 'Xoá tìm kiếm',
              onAction: _clearSearch,
              icon: VIcons.search,
            ),
          )
        else ...[
          if (showCount)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.space4,
                  vertical: VSpacing.space2,
                ),
                child: Text(
                  'Đang hiển thị ${summary.overdueCustomerCount} / ${summary.customerCount} khách',
                  style: VTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.borderDefault))),
            child: Column(
              children: [
                for (final row in state.items)
                  _CustomerRow(
                    row: row,
                    today: today,
                    selected: row.customerId == widget.selectedId,
                    showOverdueAmount: overdueOnly,
                    dense: VListDetailLayout.isSplitOf(context),
                    onTap: () => _open(row.customerId),
                  ),
                if (state.loadingMore)
                  const Padding(
                    padding: EdgeInsets.all(VSpacing.space4),
                    child: Center(child: VLoading(size: 24, strokeWidth: 3, semanticLabel: 'Đang tải thêm')),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => VSkeletonScope(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        const VSkeleton(
          height: 108,
          borderRadius: VRadius.card,
          margin: EdgeInsets.fromLTRB(VSpacing.space4, VSpacing.space4, VSpacing.space4, 0),
        ),
        const VSkeleton(
          height: VSpacing.minTouchTarget,
          borderRadius: VRadius.input,
          margin: EdgeInsets.fromLTRB(VSpacing.space4, VSpacing.space3, VSpacing.space4, 0),
        ),
        for (var i = 0; i < 6; i++)
          const VSkeleton(
            height: 56,
            margin: EdgeInsets.fromLTRB(VSpacing.space4, VSpacing.space3, VSpacing.space4, 0),
          ),
      ],
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.summary, required this.active, required this.onTap});

  final ReceivableSummary summary;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    const margin = EdgeInsets.fromLTRB(VSpacing.space4, VSpacing.space4, VSpacing.space4, 0);
    if (summary.overdueCustomerCount == 0) {
      return Container(
        margin: margin,
        padding: const EdgeInsets.all(VSpacing.space4),
        decoration: BoxDecoration(
          color: colors.surfaceBrand,
          border: Border.all(color: colors.borderBrand),
          borderRadius: BorderRadius.circular(VRadius.card),
        ),
        child: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              VIcon(icon: VIcons.success, color: colors.success),
              const SizedBox(width: VSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Không có khoản nào quá hạn',
                      style: VTypography.labelDefault.copyWith(color: colors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tất cả khách đang nợ còn trong hạn hẹn.',
                      style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    final amount = formatVnd(summary.overdueAmountMinor);
    final border = active
        ? Border.all(color: colors.danger, width: 2)
        : Border.all(color: Color.alphaBlend(colors.danger.withValues(alpha: .25), colors.surface));
    return Semantics(
      button: true,
      container: true,
      label:
          'Quá hạn $amount, ${summary.overdueCustomerCount} khách. '
          '${active ? 'Đang lọc quá hạn, bấm để xem tất cả' : 'Bấm để chỉ xem khách quá hạn'}',
      excludeSemantics: true,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: colors.dangerBg,
          border: border,
          borderRadius: BorderRadius.circular(VRadius.card),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(VRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            VIcon(icon: VIcons.warning, size: 16, color: colors.danger),
                            const SizedBox(width: VSpacing.space1),
                            Text(
                              'Quá hạn',
                              style: VTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.danger,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          amount,
                          softWrap: false,
                          style: receivableMoneyStyle(
                            context,
                            fontSize: 28,
                            color: colors.danger,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${summary.overdueCustomerCount} khách · lâu nhất ${summary.maxOverdueDays} ngày',
                          style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: VSpacing.space3),
                  if (active)
                    Text(
                      'Xem tất cả',
                      style: VTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.danger,
                      ),
                    )
                  else
                    VIcon(icon: VIcons.chevronRight, size: 16, color: VColors.neutral400),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    required this.row,
    required this.today,
    required this.selected,
    required this.showOverdueAmount,
    required this.dense,
    required this.onTap,
  });

  final CustomerReceivableRow row;
  final DateTime today;
  final bool selected;
  final bool showOverdueAmount;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final label = customerDueLabel(
      maxOverdueDays: row.maxOverdueDays,
      nextDueDate: row.nextDueDate,
      today: today,
    );
    final sub = '${row.phone != null ? '${row.phone} · ' : ''}${row.openOrderCount} đơn';
    return Material(
      color: selected ? colors.surfaceBrand : colors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: VSpacing.minTouchTarget),
          padding: EdgeInsets.symmetric(
            horizontal: VSpacing.space4,
            vertical: dense ? VSpacing.space2 : VSpacing.space3,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.borderDefault)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            row.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VTypography.labelDefault.copyWith(color: colors.textPrimary),
                          ),
                        ),
                        if (!row.isActive) ...[
                          const SizedBox(width: VSpacing.space2),
                          const ReceivableInactiveBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VSpacing.space3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatVnd(row.outstandingMinor),
                    softWrap: false,
                    style: receivableMoneyStyle(context),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReceivableDueBadge(label),
                      if (showOverdueAmount && label.kind == DueKind.overdue) ...[
                        const SizedBox(width: VSpacing.space1),
                        Text(
                          '· ${formatVnd(row.overdueAmountMinor)}',
                          softWrap: false,
                          style: VTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.danger,
                            fontFeatures: tabularFigures,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
