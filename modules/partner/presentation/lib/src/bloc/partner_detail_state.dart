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
  final bool isChangingStatus;
  final String? statusChangeMessage;
  final bool isDeletingPartner;
  final String? deleteMessage;
  final bool wasDeleted;
  final bool hasBusinessData;
  final TransactionHistoryStatus transactionStatus;
  final List<TransactionItemModel> transactions;
  final String transactionSearchQuery;

  const PartnerDetailState({
    this.status = PartnerDetailStatus.initial,
    this.partner,
    this.errorMessage,
    this.isChangingStatus = false,
    this.statusChangeMessage,
    this.isDeletingPartner = false,
    this.deleteMessage,
    this.wasDeleted = false,
    this.hasBusinessData = false,
    this.transactionStatus = TransactionHistoryStatus.ready,
    this.transactions = const [],
    this.transactionSearchQuery = '',
  });

  bool get canDelete => partner != null && !hasBusinessData && !wasDeleted;

  PartnerDetailState copyWith({
    PartnerDetailStatus? status,
    PartnerItemModel? partner,
    bool clearPartner = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isChangingStatus,
    String? statusChangeMessage,
    bool clearStatusChangeMessage = false,
    bool? isDeletingPartner,
    String? deleteMessage,
    bool clearDeleteMessage = false,
    bool? wasDeleted,
    bool? hasBusinessData,
    TransactionHistoryStatus? transactionStatus,
    List<TransactionItemModel>? transactions,
    String? transactionSearchQuery,
  }) {
    return PartnerDetailState(
      status: status ?? this.status,
      partner: clearPartner ? null : (partner ?? this.partner),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isChangingStatus: isChangingStatus ?? this.isChangingStatus,
      statusChangeMessage: clearStatusChangeMessage
          ? null
          : (statusChangeMessage ?? this.statusChangeMessage),
      isDeletingPartner: isDeletingPartner ?? this.isDeletingPartner,
      deleteMessage:
          clearDeleteMessage ? null : (deleteMessage ?? this.deleteMessage),
      wasDeleted: wasDeleted ?? this.wasDeleted,
      hasBusinessData: hasBusinessData ?? this.hasBusinessData,
      transactionStatus: transactionStatus ?? this.transactionStatus,
      transactions: transactions ?? this.transactions,
      transactionSearchQuery:
          transactionSearchQuery ?? this.transactionSearchQuery,
    );
  }
}
