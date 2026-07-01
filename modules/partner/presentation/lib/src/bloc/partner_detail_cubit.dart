import 'package:flutter_bloc/flutter_bloc.dart';
import 'partner_detail_state.dart';

class PartnerDetailCubit extends Cubit<PartnerDetailState> {
  PartnerDetailCubit() : super(const PartnerDetailState()) {
    _loadMockTransactions();
  }

  final List<TransactionItemModel> _allTransactions = [
    const TransactionItemModel(
      id: 'GR-2026-0091',
      title: 'Phiếu nhập hàng',
      date: '18/06/2026',
      status: 'Đã hoàn tất',
      amount: '12.400.000 đ',
    ),
    const TransactionItemModel(
      id: 'GR-2026-0072',
      title: 'Phiếu nhập hàng',
      date: '29/05/2026',
      status: 'Đã hoàn tất',
      amount: '8.600.000 đ',
    ),
  ];

  void _loadMockTransactions() {
    emit(state.copyWith(transactions: _allTransactions));
  }

  void searchTransactions(String query) {
    emit(state.copyWith(transactionSearchQuery: query));
    
    if (query.isEmpty) {
      emit(state.copyWith(transactions: _allTransactions));
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filtered = _allTransactions.where((t) => t.id.toLowerCase().contains(lowerQuery)).toList();
    emit(state.copyWith(transactions: filtered));
  }

  // Demo status methods
  void setTransactionStatus(TransactionHistoryStatus status) {
    emit(state.copyWith(transactionStatus: status));
  }
}
