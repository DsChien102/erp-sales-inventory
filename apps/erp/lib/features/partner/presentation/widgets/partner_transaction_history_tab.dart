import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/partner_detail_cubit.dart';
import '../bloc/partner_detail_state.dart';
import 'partner_transaction_item.dart';

class PartnerTransactionHistoryTab extends StatelessWidget {
  const PartnerTransactionHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PartnerDetailCubit, PartnerDetailState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildSearchAndDemo(context, state),
            Expanded(
              child: _buildContent(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndDemo(BuildContext context, PartnerDetailState state) {
    final dynamicColors = context.vColors;
    final cubit = context.read<PartnerDetailCubit>();

    return Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: VSearchBar(
                  hintText: 'Tìm theo mã giao dịch',
                  onChanged: (val) => cubit.searchTransactions(val),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dynamicColors.surface,
                  borderRadius: BorderRadius.circular(VRadius.input),
                  border: Border.all(color: dynamicColors.borderDefault),
                ),
                child: Icon(Icons.tune, color: dynamicColors.textPrimary, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildContent(BuildContext context, PartnerDetailState state) {
    if (state.transactionStatus == TransactionHistoryStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.transactionStatus == TransactionHistoryStatus.error) {
      return VEmptyState(
        iconData: Icons.error_outline,
        title: 'Đã xảy ra lỗi',
        description: 'Không thể tải lịch sử giao dịch',
        actionLabel: 'Thử lại',
        onActionPressed: () {
          context.read<PartnerDetailCubit>().setTransactionStatus(TransactionHistoryStatus.ready);
        },
      );
    }

    if (state.transactions.isEmpty) {
      return const VEmptyState(
        iconData: Icons.receipt_long_outlined,
        title: 'Không có giao dịch',
        description: 'Đối tác này chưa có giao dịch nào',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
      itemCount: state.transactions.length + 1, // +1 for padding
      itemBuilder: (context, index) {
        if (index == state.transactions.length) {
          return const SizedBox(height: 80); // bottom padding for edit button
        }
        return PartnerTransactionItem(transaction: state.transactions[index]);
      },
    );
  }
}
