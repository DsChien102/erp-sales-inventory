import 'package:erp/core/di/injection.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/receivable_models.dart';
import '../../data/receivable_repository.dart';
import '../../logic/customer_receivable_cubit.dart';
import '../../logic/customer_receivable_state.dart';
import '../../logic/receivable_format.dart';
import '../../logic/receivable_list_cubit.dart';
import '../../logic/receivable_permissions.dart';
import '../widgets/customer_collection_sheet.dart';
import '../widgets/receivable_parts.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String _day(DateTime d) => '${_two(d.day)}/${_two(d.month)}';

/// `dd/MM HH:mm` theo giờ máy.
String _stamp(DateTime d) {
  final l = d.toLocal();
  return '${_day(l)} ${_two(l.hour)}:${_two(l.minute)}';
}

/// CN-02 — công nợ của một khách: đầu trang, đơn còn nợ (cũ trước), lịch sử thu & cấn trừ.
class CustomerReceivableDetailPage extends StatefulWidget {
  const CustomerReceivableDetailPage({
    super.key,
    required this.customerId,
    this.repository,
    this.today,
    this.canCollect,
  });

  final String customerId;
  final ReceivableRepository? repository;

  /// Chỉ cho test / golden; mặc định ngày hôm nay của máy.
  final DateTime? today;

  /// Chỉ cho test; mặc định đọc quyền `receivable.collect` của phiên.
  final bool? canCollect;

  @override
  State<CustomerReceivableDetailPage> createState() => _CustomerReceivableDetailPageState();
}

class _CustomerReceivableDetailPageState extends State<CustomerReceivableDetailPage> {
  late final CustomerReceivableCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = CustomerReceivableCubit(
      repository: widget.repository ?? getIt<ReceivableRepository>(),
      customerId: widget.customerId,
    )..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  bool get _canCollect =>
      widget.canCollect ?? getIt<SessionController>().hasPermission(receivableCollectPermission);

  /// Cubit danh sách (CN-01) nếu có trong cây (shell công nợ).
  ReceivableListCubit? _listCubit(BuildContext context) {
    try {
      return context.read<ReceivableListCubit>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _collect(CustomerReceivableDetail detail) async {
    final listCubit = _listCubit(context);
    final outcome = await showCustomerCollectionSheet(
      context,
      customerId: detail.customer.customerId,
      customerName: detail.customer.displayName,
      orders: detail.openOrders,
      repository: widget.repository,
      today: widget.today,
    );
    if (!mounted) return;
    switch (outcome) {
      case CollectionCollected(:final amountMinor):
        VToast.show(
          context,
          title: 'Đã thu ${formatVnd(amountMinor)} từ ${detail.customer.displayName}',
          message: '',
          type: VToastType.success,
        );
        _cubit.reload();
        listCubit?.refresh();
      case CollectionNeedsReload():
        _cubit.reload();
        listCubit?.refresh();
      case CollectionCancelled():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final split = VListDetailLayout.isSplitOf(context);
    final today = widget.today ?? DateTime.now();
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: context.vColors.background,
        appBar: VAppBar(title: 'Công nợ khách hàng', showBackButton: !split),
        body: BlocBuilder<CustomerReceivableCubit, CustomerReceivableState>(
          builder: (context, state) => switch (state.detailStatus) {
            LoadStatus.loading when state.detail == null => const _Loading(),
            LoadStatus.error when state.detail == null => ReceivableEmpty(
              title: 'Không tải được công nợ',
              actionLabel: 'Thử lại',
              onAction: _cubit.load,
              icon: VIcons.warning,
            ),
            _ => _buildReady(context, state, today),
          },
        ),
      ),
    );
  }

  Widget _buildReady(BuildContext context, CustomerReceivableState state, DateTime today) {
    final detail = state.detail!;
    final colors = context.vColors;
    final canCollect = detail.outstandingMinor > 0 && _canCollect;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Head(detail: detail),
              const ReceivableSectionTitle('ĐƠN CÒN NỢ (cũ trước)'),
              if (detail.openOrders.isEmpty)
                const _Note('Không còn đơn nào nợ')
              else
                _Group(
                  children: [
                    for (var i = 0; i < detail.openOrders.length; i++)
                      _OrderRow(
                        order: detail.openOrders[i],
                        today: today,
                        first: i == 0,
                        onTap: () => context.push('/sales/orders/${detail.openOrders[i].salesOrderId}'),
                      ),
                  ],
                ),
              const ReceivableSectionTitle('LỊCH SỬ THU & CẤN TRỪ'),
              _History(state: state, cubit: _cubit),
              const SizedBox(height: VSpacing.space4),
            ],
          ),
        ),
        if (canCollect)
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space4,
                vertical: VSpacing.space3,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.borderDefault)),
              ),
              child: VButton(
                label: 'Thu tiền',
                fullWidth: true,
                onPressed: () => _collect(detail),
              ),
            ),
          ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const VSkeletonScope(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VSkeleton(height: 120, margin: EdgeInsets.all(VSpacing.space4)),
        VSkeleton(height: 64, margin: EdgeInsets.fromLTRB(16, 0, 16, 12)),
        VSkeleton(height: 64, margin: EdgeInsets.fromLTRB(16, 0, 16, 12)),
      ],
    ),
  );
}

class _Head extends StatelessWidget {
  const _Head({required this.detail});

  final CustomerReceivableDetail detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final c = detail.customer;
    final owed = detail.outstandingMinor > 0;
    final small = VTypography.bodySmall.copyWith(color: colors.textSecondary);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.space4,
        VSpacing.space5,
        VSpacing.space4,
        VSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.borderDefault)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  c.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VTypography.bodyDefault.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (c.phone != null) ...[
                const SizedBox(width: VSpacing.space2),
                Text(c.phone!, softWrap: false, style: small.copyWith(fontFeatures: tabularFigures)),
              ],
              if (!c.isActive) ...[
                const SizedBox(width: VSpacing.space2),
                const ReceivableInactiveBadge(),
              ],
            ],
          ),
          const SizedBox(height: VSpacing.space3),
          Text(
            owed ? 'Còn nợ' : 'Không còn nợ',
            style: small.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            formatVnd(detail.outstandingMinor),
            softWrap: false,
            textAlign: TextAlign.left,
            // DS không có bậc 32/700: cỡ lớn của prototype (display), ghi ở Kết quả.
            style: receivableMoneyStyle(context, fontSize: 32, height: 1.1).copyWith(letterSpacing: -0.64),
          ),
          if (owed) ...[
            const SizedBox(height: VSpacing.space1),
            Row(
              children: [
                Text('${detail.openOrderCount} đơn ·', style: small),
                const SizedBox(width: VSpacing.space1),
                if (detail.overdueOrderCount > 0) ...[
                  VIcon(icon: VIcons.warning, size: 16, color: colors.danger),
                  const SizedBox(width: VSpacing.space1),
                  Text(
                    '${detail.overdueOrderCount} quá hạn',
                    style: small.copyWith(fontWeight: FontWeight.w600, color: colors.danger),
                  ),
                ] else
                  Text('${detail.overdueOrderCount} quá hạn', style: small),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(VRadius.card),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4, vertical: VSpacing.space3),
    child: Text(
      text,
      style: VTypography.bodyDefault.copyWith(color: context.vColors.textSecondary),
    ),
  );
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.order,
    required this.today,
    required this.first,
    required this.onTap,
  });

  final OpenReceivableOrder order;
  final DateTime today;
  final bool first;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final due = orderDueLabel(dueDate: order.dueDate, overdueDays: order.overdueDays, today: today);
    return Material(
      color: due.kind == DueKind.overdue ? colors.dangerBg : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            VSpacing.space3,
            VSpacing.space3,
            VSpacing.space3,
          ),
          decoration: BoxDecoration(
            border: first ? null : Border(top: BorderSide(color: colors.borderDefault)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.orderCode} · ${_day(order.completedAt.toLocal())}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: receivableMoneyStyle(context),
                    ),
                    const SizedBox(height: VSpacing.space1),
                    ReceivableDueBadge(due),
                  ],
                ),
              ),
              const SizedBox(width: VSpacing.space3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Còn nợ ${formatVnd(order.outstandingMinor)}',
                    softWrap: false,
                    style: receivableMoneyStyle(context),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tổng ${formatVnd(order.payableMinor)}',
                    softWrap: false,
                    style: VTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: VSpacing.space3),
              VIcon(icon: VIcons.chevronRight, size: 16, color: VColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.state, required this.cubit});

  final CustomerReceivableState state;
  final CustomerReceivableCubit cubit;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    switch (state.historyStatus) {
      case LoadStatus.loading:
        return const VSkeletonScope(
          child: Column(
            children: [
              VSkeleton(height: 56, margin: EdgeInsets.fromLTRB(16, 0, 16, 8)),
              VSkeleton(height: 56, margin: EdgeInsets.fromLTRB(16, 0, 16, 8)),
            ],
          ),
        );
      case LoadStatus.error:
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.space4,
            vertical: VSpacing.space5,
          ),
          child: Column(
            children: [
              Text(
                'Không tải được',
                style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: VSpacing.space2),
              VButton(
                label: 'Thử lại',
                variant: VButtonVariant.secondary,
                onPressed: cubit.retryHistory,
              ),
            ],
          ),
        );
      case LoadStatus.ready:
        if (state.history.isEmpty) return const _Note('Chưa có lần thu nào');
        return _Group(
          children: [
            for (var i = 0; i < state.history.length; i++)
              _HistoryRow(item: state.history[i], first: i == 0),
            if (state.historyCursor != null)
              InkWell(
                onTap: state.historyLoadingMore ? null : cubit.loadMoreHistory,
                child: Container(
                  constraints: const BoxConstraints(minHeight: VSpacing.minTouchTarget),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.borderDefault)),
                  ),
                  child: state.historyLoadingMore
                      ? const VLoading(size: 20, strokeWidth: 3, semanticLabel: 'Đang tải thêm')
                      : Text(
                          'Xem thêm',
                          style: VTypography.labelDefault.copyWith(color: colors.textBrand),
                        ),
                ),
              ),
          ],
        );
    }
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item, required this.first});

  final ReceivableHistoryItem item;
  final bool first;

  /// Chữ chép từ `historyRow` của prototype `cn02.js`.
  (String title, List<String> meta) _text() {
    final amount = formatVndBare(item.amountMinor);
    final when = _stamp(item.occurredAt);
    final by = item.actorDisplayName;
    switch (item.kind) {
      case ReceivableHistoryKind.customerCollection:
        final method = item.paymentMethodCode == 'cash'
            ? 'Tiền mặt'
            : 'Chuyển khoản${item.externalReference != null ? ' ${item.externalReference}' : ''}';
        return (
          'Thu $amount · $method',
          [
            '$when${by != null ? ' · $by' : ''}',
            'Vào: ${item.allocations.map((a) => '${a.orderCode} ${formatVndBare(a.amountMinor)}').join(', ')}',
          ],
        );
      case ReceivableHistoryKind.orderCollection:
        return ('Thu $amount · đơn ${item.orderCode}', [when]);
      case ReceivableHistoryKind.offset:
        return (
          'Cấn trừ $amount · từ trả hàng đơn ${item.sourceOrderCode} '
              '(phiếu ${item.returnExchangeReference}) sang đơn ${item.targetOrderCode}',
          ['$when${by != null ? ' · $by' : ''}'],
        );
      case ReceivableHistoryKind.refund:
        return ('Hoàn $amount · đơn ${item.orderCode}', [when]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final (title, meta) = _text();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4, vertical: VSpacing.space3),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: VTypography.labelDefault.copyWith(
              color: colors.textPrimary,
              fontFeatures: tabularFigures,
            ),
          ),
          for (final m in meta) ...[
            const SizedBox(height: 2),
            Text(m, style: VTypography.bodySmall.copyWith(color: colors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
