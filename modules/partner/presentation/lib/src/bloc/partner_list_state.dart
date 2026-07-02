enum PartnerListStatus { initial, loading, success, failure }

class PartnerItemModel {
  final String id;
  final String avatarText;
  final String name;
  final String role;
  final String status;
  final String phone;
  final String email;
  final String taxId;
  final String updatedAt;
  final String address;
  final String note;
  final String profileType;
  final String creator;
  final String createdAt;
  final String updatedBy;
  final String billingName;
  final String billingAddress;
  final String billingEmail;
  final int version;

  const PartnerItemModel({
    required this.id,
    required this.avatarText,
    required this.name,
    required this.role,
    required this.status,
    required this.phone,
    required this.email,
    required this.taxId,
    required this.updatedAt,
    this.address = '',
    this.note = '',
    this.profileType = '',
    this.creator = '',
    this.createdAt = '',
    this.updatedBy = '',
    this.billingName = '',
    this.billingAddress = '',
    this.billingEmail = '',
    this.version = 1,
    this.hasBusinessData = false,
  });

  final bool hasBusinessData;
}

class PartnerListState {
  final PartnerListStatus status;
  final List<PartnerItemModel> partners;
  final int totalCount;
  final bool isLoadingMore;
  final String searchQuery;
  final String? filterRole;
  final String? filterProfileType;
  final String? filterStatus;
  final String? errorMessage;

  const PartnerListState({
    this.status = PartnerListStatus.initial,
    this.partners = const [],
    this.totalCount = 0,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.filterRole,
    this.filterProfileType,
    this.filterStatus,
    this.errorMessage,
  });

  bool get hasMore => partners.length < totalCount;

  PartnerListState copyWith({
    PartnerListStatus? status,
    List<PartnerItemModel>? partners,
    int? totalCount,
    bool? isLoadingMore,
    String? searchQuery,
    String? filterRole,
    String? filterProfileType,
    String? filterStatus,
    String? errorMessage,
    bool clearRole = false,
    bool clearProfileType = false,
    bool clearStatus = false,
    bool clearErrorMessage = false,
  }) {
    return PartnerListState(
      status: status ?? this.status,
      partners: partners ?? this.partners,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      filterRole: clearRole ? null : (filterRole ?? this.filterRole),
      filterProfileType:
          clearProfileType ? null : (filterProfileType ?? this.filterProfileType),
      filterStatus: clearStatus ? null : (filterStatus ?? this.filterStatus),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
