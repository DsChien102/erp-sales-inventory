import 'package:vet45_iam_application/application.dart';

enum PlatformUsersStatus {
  initial,
  loading,
  success,
  failure,
  unauthorized,
}

/// UI state for platform users list (Admin / EP-01 US-01).
final class PlatformUsersState {
  const PlatformUsersState({
    this.status = PlatformUsersStatus.initial,
    this.users = const [],
    this.detailsById = const {},
    this.searchQuery = '',
    this.selectedFilterIndex = 0,
    this.filterStatus = 0,
    this.filterActivation = 0,
    this.filterEmail = 0,
    this.errorMessage,
  });

  final PlatformUsersStatus status;
  final List<PlatformUserSummaryDto> users;
  final Map<String, PlatformUserDetailDto> detailsById;
  final String searchQuery;
  final int selectedFilterIndex;
  final int filterStatus;
  final int filterActivation;
  final int filterEmail;
  final String? errorMessage;

  bool get isFilterApplied =>
      filterStatus != 0 || filterActivation != 0 || filterEmail != 0;

  List<PlatformUserSummaryDto> get filteredUsers {
    return users.where((summary) {
      final detail = detailsById[summary.userId];
      final status = detail?.status ?? summary.status;

      final chip = _statusForIndex(selectedFilterIndex);
      if (chip != null && status != chip) return false;

      if (filterStatus == 1 && status != PlatformUserStatus.active) return false;
      if (filterStatus == 2 && status != PlatformUserStatus.suspended) {
        return false;
      }

      if (filterActivation == 1 &&
          status != PlatformUserStatus.active &&
          status != PlatformUserStatus.suspended) {
        return false;
      }
      if (filterActivation == 2 &&
          status != PlatformUserStatus.pendingActivation) {
        return false;
      }
      if (filterActivation == 3) return false;

      if (detail != null) {
        if (filterEmail == 1 && !detail.emailVerified) return false;
        if (filterEmail == 2 && detail.emailVerified) return false;
      }

      return true;
    }).toList();
  }

  static PlatformUserStatus? _statusForIndex(int index) {
    return switch (index) {
      1 => PlatformUserStatus.active,
      2 => PlatformUserStatus.pendingActivation,
      3 => PlatformUserStatus.suspended,
      _ => null,
    };
  }

  PlatformUsersState copyWith({
    PlatformUsersStatus? status,
    List<PlatformUserSummaryDto>? users,
    Map<String, PlatformUserDetailDto>? detailsById,
    String? searchQuery,
    int? selectedFilterIndex,
    int? filterStatus,
    int? filterActivation,
    int? filterEmail,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlatformUsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      detailsById: detailsById ?? this.detailsById,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilterIndex: selectedFilterIndex ?? this.selectedFilterIndex,
      filterStatus: filterStatus ?? this.filterStatus,
      filterActivation: filterActivation ?? this.filterActivation,
      filterEmail: filterEmail ?? this.filterEmail,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
