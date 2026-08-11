import 'package:vet45_iam_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/iam_ui_failure.dart';
import 'tenant_audit_filter.dart';

final class TenantAuditLogsState {
  const TenantAuditLogsState({
    this.status = IamLoadStatus.initial,
    this.items = const [],
    this.nextCursor,
    required this.filters,
    this.isLoadingMore = false,
    this.failure,
    this.selectedDetail,
    this.detailStatus = IamLoadStatus.initial,
    this.detailFailure,
  });

  final IamLoadStatus status;
  final List<TenantAuditLogSummaryDto> items;
  final String? nextCursor;
  final TenantAuditFilter filters;
  final bool isLoadingMore;
  final IamUiFailure? failure;
  final TenantAuditLogDetailDto? selectedDetail;
  final IamLoadStatus detailStatus;
  final IamUiFailure? detailFailure;

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  TenantAuditLogsState copyWith({
    IamLoadStatus? status,
    List<TenantAuditLogSummaryDto>? items,
    String? nextCursor,
    TenantAuditFilter? filters,
    bool? isLoadingMore,
    IamUiFailure? failure,
    TenantAuditLogDetailDto? selectedDetail,
    IamLoadStatus? detailStatus,
    IamUiFailure? detailFailure,
    bool clearNextCursor = false,
    bool clearFailure = false,
    bool clearDetail = false,
    bool clearDetailFailure = false,
  }) {
    return TenantAuditLogsState(
      status: status ?? this.status,
      items: items ?? this.items,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      filters: filters ?? this.filters,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : (failure ?? this.failure),
      selectedDetail:
          clearDetail ? null : (selectedDetail ?? this.selectedDetail),
      detailStatus: detailStatus ?? this.detailStatus,
      detailFailure: clearDetailFailure
          ? null
          : (detailFailure ?? this.detailFailure),
    );
  }
}
