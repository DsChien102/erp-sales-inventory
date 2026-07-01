enum TransactionHistoryStatus { ready, loading, error }

class TransactionItemModel {
  final String id;
  final String title;
  final String date;
  final String status;
  final String amount;

  const TransactionItemModel({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    required this.amount,
  });
}

class PartnerDetailState {
  final TransactionHistoryStatus transactionStatus;
  final List<TransactionItemModel> transactions;
  final String transactionSearchQuery;

  const PartnerDetailState({
    this.transactionStatus = TransactionHistoryStatus.ready,
    this.transactions = const [],
    this.transactionSearchQuery = '',
  });

  PartnerDetailState copyWith({
    TransactionHistoryStatus? transactionStatus,
    List<TransactionItemModel>? transactions,
    String? transactionSearchQuery,
  }) {
    return PartnerDetailState(
      transactionStatus: transactionStatus ?? this.transactionStatus,
      transactions: transactions ?? this.transactions,
      transactionSearchQuery: transactionSearchQuery ?? this.transactionSearchQuery,
    );
  }
}
