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
  });
}

class PartnerListState {
  final PartnerListStatus status;
  final List<PartnerItemModel> partners;
  final String searchQuery;
  final String? filterRole;
  final String? filterStatus;

  const PartnerListState({
    this.status = PartnerListStatus.initial,
    this.partners = const [],
    this.searchQuery = '',
    this.filterRole,
    this.filterStatus = 'Đang hoạt động',
  });

  PartnerListState copyWith({
    PartnerListStatus? status,
    List<PartnerItemModel>? partners,
    String? searchQuery,
    String? filterRole,
    String? filterStatus,
    bool clearRole = false,
    bool clearStatus = false,
  }) {
    return PartnerListState(
      status: status ?? this.status,
      partners: partners ?? this.partners,
      searchQuery: searchQuery ?? this.searchQuery,
      filterRole: clearRole ? null : (filterRole ?? this.filterRole),
      filterStatus: clearStatus ? null : (filterStatus ?? this.filterStatus),
    );
  }
}
