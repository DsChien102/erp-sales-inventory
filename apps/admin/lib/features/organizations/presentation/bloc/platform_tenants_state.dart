import 'package:vet45_iam_presentation/presentation.dart';

enum PlatformTenantsStatus {
  initial,
  loading,
  success,
  failure,
  unauthorized,
}

final class PlatformTenantsState {
  const PlatformTenantsState({
    this.status = PlatformTenantsStatus.initial,
    this.tenants = const [],
    this.searchQuery = '',
    this.filterCriteria = const OrganizationFilterCriteria(),
    this.errorMessage,
  });

  final PlatformTenantsStatus status;
  final List<OrganizationUiModel> tenants;
  final String searchQuery;
  final OrganizationFilterCriteria filterCriteria;
  final String? errorMessage;

  List<OrganizationUiModel> get filteredTenants {
    return tenants.where((org) {
      if (filterCriteria.status != OrganizationStatus.all &&
          org.status != filterCriteria.status) {
        return false;
      }
      if (filterCriteria.lifecycle != 'Tất cả') {
        if (filterCriteria.lifecycle == 'Tạm ngừng' &&
            org.status != OrganizationStatus.suspended) {
          return false;
        }
        if (filterCriteria.lifecycle == 'Đã đóng' &&
            org.status != OrganizationStatus.closed) {
          return false;
        }
      }
      final q = searchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        final nameMatch = org.name.toLowerCase().contains(q);
        final codeMatch = org.code.toLowerCase().contains(q);
        return nameMatch || codeMatch;
      }
      return true;
    }).toList();
  }

  PlatformTenantsState copyWith({
    PlatformTenantsStatus? status,
    List<OrganizationUiModel>? tenants,
    String? searchQuery,
    OrganizationFilterCriteria? filterCriteria,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlatformTenantsState(
      status: status ?? this.status,
      tenants: tenants ?? this.tenants,
      searchQuery: searchQuery ?? this.searchQuery,
      filterCriteria: filterCriteria ?? this.filterCriteria,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
