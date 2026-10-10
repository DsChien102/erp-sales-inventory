import 'package:erp/core/iam/iam_load_status.dart';
import 'package:erp/core/iam/iam_ui_failure.dart';

import '../data/models/platform_tenant.dart';

/// Chip lọc trạng thái ở C1. Không có "Đang thiết lập" (KI-05).
enum PlatformTenantFilter {
  all('Tất cả', null),
  active('Đang hoạt động', 'active'),
  suspended('Tạm ngừng', 'suspended'),
  closed('Đã đóng', 'closed');

  const PlatformTenantFilter(this.label, this.wire);

  final String label;

  /// Giá trị `p_status`; `null` = tất cả.
  final String? wire;
}

final class PlatformTenantsState {
  const PlatformTenantsState({
    this.status = IamLoadStatus.initial,
    this.items = const [],
    this.query = '',
    this.filter = PlatformTenantFilter.all,
    this.nextCursor,
    this.isLoadingMore = false,
    this.failure,
  });

  final IamLoadStatus status;
  final List<PlatformTenantSummary> items;
  final String query;
  final PlatformTenantFilter filter;
  final String? nextCursor;
  final bool isLoadingMore;
  final IamUiFailure? failure;

  bool get hasMore => nextCursor != null;

  bool get isFiltered => query.trim().isNotEmpty || filter != PlatformTenantFilter.all;

  PlatformTenantsState copyWith({
    IamLoadStatus? status,
    List<PlatformTenantSummary>? items,
    String? query,
    PlatformTenantFilter? filter,
    String? nextCursor,
    bool? isLoadingMore,
    IamUiFailure? failure,
    bool clearCursor = false,
    bool clearFailure = false,
  }) {
    return PlatformTenantsState(
      status: status ?? this.status,
      items: items ?? this.items,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
