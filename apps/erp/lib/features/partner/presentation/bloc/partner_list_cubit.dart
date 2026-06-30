import 'package:flutter_bloc/flutter_bloc.dart';
import 'partner_list_state.dart';

class PartnerListCubit extends Cubit<PartnerListState> {
  PartnerListCubit() : super(const PartnerListState()) {
    _loadMockData();
  }

  final List<PartnerItemModel> _allPartners = [
    const PartnerItemModel(
      id: '1',
      avatarText: 'MP',
      name: 'Đại lý Chăn nuôi Minh Phát',
      role: 'Nhà cung cấp',
      status: 'Đang hoạt động',
      phone: '028 3822 5511',
      email: 'minhphat@example.com',
      taxId: '0109988776',
      updatedAt: '18/06/2026',
    ),
    const PartnerItemModel(
      id: '2',
      avatarText: 'TH',
      name: 'Trần Thị Hoa',
      role: 'Khách hàng',
      status: 'Đang hoạt động',
      phone: '0987 654 321',
      email: 'hoa@example.com',
      taxId: '',
      updatedAt: '15/06/2026',
    ),
    const PartnerItemModel(
      id: '3',
      avatarText: 'ĐT',
      name: 'Nguyễn Đức Trí',
      role: 'Khách hàng & NCC',
      status: 'Ngừng hoạt động',
      phone: '0901 234 567',
      email: 'tri@example.com',
      taxId: '023131231',
      updatedAt: '10/06/2026',
    ),
    const PartnerItemModel(
      id: '4',
      avatarText: 'VA',
      name: 'Nguyễn Văn An',
      role: 'Khách hàng',
      status: 'Đang hoạt động',
      phone: '0912 345 678',
      email: 'an@example.com',
      taxId: '',
      updatedAt: '30/05/2026',
    ),
  ];

  void _loadMockData() {
    emit(state.copyWith(status: PartnerListStatus.loading));
    
    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _applyFilters();
    });
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFilters();
  }

  void updateFilter({String? role, String? status}) {
    emit(state.copyWith(
      filterRole: role,
      filterStatus: status,
      clearRole: role == null,
      clearStatus: status == null,
    ));
    _applyFilters();
  }

  void clearFilters() {
    emit(state.copyWith(
      clearRole: true,
      clearStatus: true,
    ));
    _applyFilters();
  }

  void _applyFilters() {
    var filteredList = _allPartners;

    // Apply search filter
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filteredList = filteredList.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.phone.toLowerCase().contains(query) ||
            p.email.toLowerCase().contains(query) ||
            p.taxId.toLowerCase().contains(query);
      }).toList();
    }

    // Apply role filter
    if (state.filterRole != null && state.filterRole!.isNotEmpty) {
      filteredList = filteredList.where((p) {
        return p.role == state.filterRole;
      }).toList();
    }

    // Apply status filter
    if (state.filterStatus != null && state.filterStatus!.isNotEmpty) {
      filteredList = filteredList.where((p) {
        return p.status == state.filterStatus;
      }).toList();
    }

    emit(state.copyWith(
      status: PartnerListStatus.success,
      partners: filteredList,
    ));
  }
}
