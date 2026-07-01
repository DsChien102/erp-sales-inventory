import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_domain/domain.dart';
import '../bloc/partner_detail_cubit.dart';
import '../bloc/partner_detail_state.dart';
import '../bloc/partner_list_state.dart'; // Import PartnerItemModel
import 'partner_transaction_filter_bottom_sheet.dart';
import 'partner_transaction_item.dart';

class PartnerTransactionHistoryTab extends StatelessWidget {
  final PartnerItemModel partner;
  final bool isTraceFlow;

  const PartnerTransactionHistoryTab({
    super.key,
    required this.partner,
    this.isTraceFlow = false,
  });

  @override
  Widget build(BuildContext context) {
    // FR-05: Handle deleted status restriction
    if (partner.status == 'Đã xóa' && !isTraceFlow) {
      return const VEmptyState(
        iconData: Icons.block_outlined,
        title: 'Hạn chế truy cập',
        description: 'Không thể xem lịch sử giao dịch của đối tác đã bị xóa.',
      );
    }

    return BlocBuilder<PartnerDetailCubit, PartnerDetailState>(
      builder: (context, state) {
        return _PartnerTransactionHistoryTabContent(
          state: state,
          partnerRole: partner.role,
        );
      },
    );
  }
}

class _PartnerTransactionHistoryTabContent extends StatefulWidget {
  const _PartnerTransactionHistoryTabContent({
    required this.state,
    required this.partnerRole,
  });

  final PartnerDetailState state;
  final String partnerRole;

  @override
  State<_PartnerTransactionHistoryTabContent> createState() =>
      _PartnerTransactionHistoryTabContentState();
}

class _PartnerTransactionHistoryTabContentState
    extends State<_PartnerTransactionHistoryTabContent> {
  final _historySearchController = TextEditingController();
  String _timeFilter = 'all';
  String _typeFilter = 'all';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _historySearchController.dispose();
    super.dispose();
  }

  void _showTransactionFilter(BuildContext context) {
    showVBottomSheet(
      context: context,
      child: TransactionFilterBottomSheet(
        initialTimeFilter: _timeFilter,
        initialTypeFilter: _typeFilter,
        initialStatusFilter: _statusFilter,
        partnerRole: widget.partnerRole,
        onApply: (time, type, status) {
          setState(() {
            _timeFilter = time;
            _typeFilter = type;
            _statusFilter = status;
          });
          _fetchFilteredHistory();
        },
        onReset: () {
          setState(() {
            _timeFilter = 'all';
            _typeFilter = 'all';
            _statusFilter = 'all';
          });
          _fetchFilteredHistory();
        },
      ),
    );
  }

  void _fetchFilteredHistory() {
    final partnerId = widget.state.partner?.id;
    if (partnerId == null || partnerId.isEmpty) return;

    DateTime? fromDate;
    if (_timeFilter != 'all') {
      final now = DateTime.now();
      fromDate = switch (_timeFilter) {
        '30d' => now.subtract(const Duration(days: 30)),
        '90d' => now.subtract(const Duration(days: 90)),
        '1y' => now.subtract(const Duration(days: 365)),
        _ => null,
      };
    }

    Set<String>? types;
    if (_typeFilter != 'all') {
      types = switch (_typeFilter) {
        'sales' => {'sales_order', 'sales', 'Đơn bán hàng'},
        'purchase' => {'purchase_order', 'purchase', 'import', 'goods_receipt', 'Phiếu nhập hàng'},
        'invoice' => {'sales_invoice', 'invoice', 'Hóa đơn bán hàng'},
        'return' => {'return_order', 'return', 'Phiếu đổi/trả'},
        _ => null,
      };
    }

    final keyword = _historySearchController.text.trim();

    final criteria = PartnerTransactionHistoryCriteria(
      from: fromDate,
      transactionTypes: types,
      keyword: keyword.isNotEmpty ? keyword : null,
    );

    context.read<PartnerDetailCubit>().loadTransactionHistory(
      partnerId,
      criteria: criteria,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _timeFilter != 'all' || _typeFilter != 'all' || _statusFilter != 'all';

    return Column(
      children: [
        // Search + Filter row
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.screenMobile,
            VSpacing.space3,
            VSpacing.screenMobile,
            VSpacing.space2,
          ),
          child: Row(
            children: [
              Expanded(
                child: _CustomSearchBar(
                  controller: _historySearchController,
                  onChanged: (_) => _fetchFilteredHistory(),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              _HistoryFilterButton(
                isSelected: hasActiveFilters,
                onTap: () => _showTransactionFilter(context),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: switch (widget.state.historyStatus) {
            PartnerHistoryStatus.initial ||
            PartnerHistoryStatus.loading => const Center(child: CircularProgressIndicator()),
            PartnerHistoryStatus.error => const Center(
              child: VEmptyState(
                iconData: Icons.history_toggle_off_outlined,
                title: 'Không thể tải lịch sử giao dịch',
                description: 'Vui lòng thử lại sau.',
              ),
            ),
            PartnerHistoryStatus.loaded => Builder(
              builder: (context) {
                final filtered = widget.state.history.where((tx) {
                  if (_statusFilter == 'all') return true;
                  final s = (tx.status ?? '').toLowerCase();
                  return switch (_statusFilter) {
                    'done' =>
                      s.contains('done') || s.contains('hoàn tất') || s.contains('complete'),
                    'delivered' => s.contains('deliver') || s.contains('giao'),
                    'draft' => s.contains('draft') || s.contains('nhập') || s.contains('new'),
                    'cancelled' => s.contains('cancel') || s.contains('hủy'),
                    _ => true,
                  };
                }).toList();

                if (filtered.isEmpty) {
                  return VEmptyState(
                    iconData: Icons.history,
                    title: widget.state.history.isEmpty
                        ? 'Chưa có lịch sử giao dịch'
                        : 'Không tìm thấy giao dịch phù hợp',
                    description: widget.state.history.isEmpty
                        ? 'Các giao dịch phát sinh sẽ hiển thị tại đây.'
                        : 'Thử đổi từ khóa hoặc bộ lọc đang áp dụng.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(VSpacing.screenMobile),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: VSpacing.space3),
                  itemBuilder: (context, index) {
                    final tx = filtered[index];
                    return PartnerTransactionItem(transaction: tx);
                  },
                );
              },
            ),
          },
        ),
      ],
    );
  }
}

class _CustomSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _CustomSearchBar({
    required this.controller,
    this.onChanged,
  });

  @override
  State<_CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<_CustomSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return AnimatedContainer(
      duration: VDuration.fast,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.space3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.r12),
        border: Border.all(
          color: _isFocused ? colors.primary : colors.borderDefault,
          width: _isFocused ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: colors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: VSpacing.space2),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onTapOutside: (_) => _focusNode.unfocus(),
              style: VTypography.bodyDefault.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm theo mã giao dịch',
                hintStyle: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                widget.controller.clear();
                if (widget.onChanged != null) {
                  widget.onChanged!('');
                }
              },
              child: Icon(
                Icons.clear,
                color: colors.textSecondary,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryFilterButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _HistoryFilterButton({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: VDuration.fast,
        height: 44,
        width: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.surfaceBrand : colors.surface,
          borderRadius: BorderRadius.circular(VRadius.r12),
          border: Border.all(
            color: isSelected ? colors.primary : colors.borderDefault,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Icon(
          Icons.tune_rounded,
          color: isSelected ? colors.primary : colors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}
