import 'partner_list_state.dart';

enum PartnerDetailStatus { initial, loading, success, failure }

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
  final PartnerDetailStatus status;
  final PartnerItemModel? partner;
  final String? errorMessage;
  final TransactionHistoryStatus transactionStatus;
  final List<TransactionItemModel> transactions;
  final String transactionSearchQuery;

  const PartnerDetailState({
    this.status = PartnerDetailStatus.initial,
    this.partner,
    this.errorMessage,
    this.transactionStatus = TransactionHistoryStatus.ready,
    this.transactions = const [],
    this.transactionSearchQuery = '',
  });

  PartnerDetailState copyWith({
    PartnerDetailStatus? status,
    PartnerItemModel? partner,
    String? errorMessage,
    bool clearErrorMessage = false,
    TransactionHistoryStatus? transactionStatus,
    List<TransactionItemModel>? transactions,
    String? transactionSearchQuery,
  }) {
    return PartnerDetailState(
      status: status ?? this.status,
      partner: partner ?? this.partner,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      transactionStatus: transactionStatus ?? this.transactionStatus,
      transactions: transactions ?? this.transactions,
      transactionSearchQuery:
          transactionSearchQuery ?? this.transactionSearchQuery,
    );
  }
}
