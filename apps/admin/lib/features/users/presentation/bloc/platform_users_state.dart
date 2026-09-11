import 'package:vet45_iam_application/application.dart';
import 'package:admin/features/iam/presentation.dart';

final class PlatformUsersState {
  const PlatformUsersState({
    this.status = IamLoadStatus.initial,
    this.users = const [],
    this.searchQuery = '',
    this.statusFilter,
    this.nextCursor,
    this.isLoadingMore = false,
    this.failure,
  });

  final IamLoadStatus status;
  final List<PlatformUserSummaryDto> users;
  final String searchQuery;
  final PlatformUserStatus? statusFilter;
  final String? nextCursor;
  final bool isLoadingMore;
  final IamUiFailure? failure;

  bool get isFilterApplied => statusFilter != null;
  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  PlatformUsersState copyWith({
    IamLoadStatus? status,
    List<PlatformUserSummaryDto>? users,
    String? searchQuery,
    PlatformUserStatus? statusFilter,
    String? nextCursor,
    bool? isLoadingMore,
    IamUiFailure? failure,
    bool clearStatusFilter = false,
    bool clearNextCursor = false,
    bool clearFailure = false,
  }) {
    return PlatformUsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
