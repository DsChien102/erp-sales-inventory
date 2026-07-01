import 'partner_list_state.dart';
import '../models/partner_transaction_history_item_dto.dart';

enum PartnerDetailStatus { initial, loading, success, failure }

enum PartnerHistoryStatus {
  initial,
  loading,
  loaded,
  error,
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
  final PartnerHistoryStatus historyStatus;
  final List<PartnerTransactionHistoryItemDto> history;

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
    this.historyStatus = PartnerHistoryStatus.initial,
    this.history = const [],
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
    PartnerHistoryStatus? historyStatus,
    List<PartnerTransactionHistoryItemDto>? history,
  }) {
    return PartnerDetailState(
      status: status ?? this.status,
      partner: clearPartner ? null : (partner ?? this.partner),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isChangingStatus: isChangingStatus ?? this.isChangingStatus,
      statusChangeMessage: clearStatusChangeMessage
          ? null
          : (statusChangeMessage ?? this.statusChangeMessage),
      isDeletingPartner: isDeletingPartner ?? this.isDeletingPartner,
      deleteMessage: clearDeleteMessage ? null : (deleteMessage ?? this.deleteMessage),
      wasDeleted: wasDeleted ?? this.wasDeleted,
      hasBusinessData: hasBusinessData ?? this.hasBusinessData,
      historyStatus: historyStatus ?? this.historyStatus,
      history: history ?? this.history,
    );
  }
}
