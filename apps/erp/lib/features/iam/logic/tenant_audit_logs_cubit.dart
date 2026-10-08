import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../data/audit_log_repository.dart';
import '../data/models/tenant_audit_log.dart';
import 'iam_load_status.dart';
import 'iam_ui_failure_mapper.dart';
import 'tenant_audit_event_catalog.dart';
import 'tenant_audit_filter.dart';
import 'tenant_audit_logs_state.dart';

final class TenantAuditLogsCubit extends Cubit<TenantAuditLogsState> {
  TenantAuditLogsCubit({
    required AuditLogRepository auditLogs,
    TenantAuditFilter? initialFilter,
    DateTime Function()? clockLocal,
  }) : _auditLogs = auditLogs,
       _clockLocal = clockLocal ?? DateTime.now,
       super(
         TenantAuditLogsState(
           filters:
               initialFilter ??
               TenantAuditFilter.last30Days(nowLocal: (clockLocal ?? DateTime.now)()),
         ),
       );

  final AuditLogRepository _auditLogs;
  final DateTime Function() _clockLocal;

  Future<void> search({bool reset = true}) async {
    if (isClosed) return;
    if (reset) {
      emit(
        state.copyWith(
          status: IamLoadStatus.loading,
          items: const [],
          totalCount: 0,
          clearNextCursor: true,
          clearFailure: true,
          isLoadingMore: false,
        ),
      );
    } else {
      if (state.isLoadingMore || !state.hasMore) return;
      emit(state.copyWith(isLoadingMore: true, clearFailure: true));
    }

    try {
      final trimmedQuery = state.filters.query?.trim();
      final hasQuery = trimmedQuery != null && trimmedQuery.isNotEmpty;
      final matchingEventCodes = hasQuery
          ? TenantAuditEventCatalog.matchingEventCodes(trimmedQuery)
          : const <String>[];
      final effectiveQuery = hasQuery && matchingEventCodes.isEmpty ? trimmedQuery : null;
      final effectiveEventCodes = _mergeEventCodes(
        structured: state.filters.eventCodes,
        derived: matchingEventCodes,
      );
      final page = await _auditLogs.search(
        from: toUtcStartOfLocalDay(state.filters.fromLocal),
        to: toUtcEndExclusiveOfLocalDay(state.filters.toLocal),
        query: effectiveQuery,
        result: state.filters.result?.code,
        eventCategory: state.filters.eventCategory?.code,
        subjectType: state.filters.subjectType,
        eventCodes: effectiveEventCodes,
        cursor: reset ? null : state.nextCursor,
      );
      if (isClosed) return;

      final merged = reset ? page.items : _dedupeAppend(state.items, page.items);
      emit(
        state.copyWith(
          status: IamLoadStatus.success,
          items: merged,
          totalCount: page.totalCount,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          isLoadingMore: false,
          clearFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: reset ? IamLoadStatus.failure : state.status,
          isLoadingMore: false,
          failure: IamUiFailureMapper.from(error),
        ),
      );
    }
  }

  Future<void> loadNextPage() => search(reset: false);

  Future<void> applyFilter(TenantAuditFilter filter) async {
    if (isClosed) return;
    emit(state.copyWith(filters: filter));
    await search(reset: true);
  }

  Future<void> clearFilter() async {
    await applyFilter(TenantAuditFilter.last30Days(nowLocal: _clockLocal()));
  }

  Future<void> loadDetail(String auditLogId) async {
    if (isClosed) return;
    emit(
      state.copyWith(
        detailStatus: IamLoadStatus.loading,
        clearDetail: true,
        clearDetailFailure: true,
      ),
    );
    try {
      final detail = await _auditLogs.getDetail(auditLogId);
      if (isClosed) return;
      emit(
        state.copyWith(
          detailStatus: IamLoadStatus.success,
          selectedDetail: detail,
          clearDetailFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          detailStatus: IamLoadStatus.failure,
          clearDetail: true,
          detailFailure: IamUiFailureMapper.from(error),
        ),
      );
    }
  }

  void clearDetail() {
    if (isClosed) return;
    emit(
      state.copyWith(
        clearDetail: true,
        clearDetailFailure: true,
        detailStatus: IamLoadStatus.initial,
      ),
    );
  }

  /// Business calendar day start (ICT) → UTC.
  static DateTime toUtcStartOfLocalDay(DateTime local) {
    return DateTime.utc(local.year, local.month, local.day).subtract(VDateTime.ictOffset);
  }

  /// Business next-day midnight (ICT, end-exclusive) → UTC.
  static DateTime toUtcEndExclusiveOfLocalDay(DateTime local) {
    return DateTime.utc(local.year, local.month, local.day + 1).subtract(VDateTime.ictOffset);
  }

  List<TenantAuditLogSummaryDto> _dedupeAppend(
    List<TenantAuditLogSummaryDto> existing,
    List<TenantAuditLogSummaryDto> incoming,
  ) {
    final seen = <String>{for (final row in existing) row.auditLogId};
    final out = List<TenantAuditLogSummaryDto>.of(existing);
    for (final row in incoming) {
      if (seen.add(row.auditLogId)) {
        out.add(row);
      }
    }
    return out;
  }

  static List<String>? _mergeEventCodes({
    required List<String>? structured,
    required List<String> derived,
  }) {
    if (derived.isEmpty) return structured;
    if (structured == null || structured.isEmpty) return derived;
    final structuredSet = structured.toSet();
    return derived.where(structuredSet.contains).toList(growable: false);
  }
}
