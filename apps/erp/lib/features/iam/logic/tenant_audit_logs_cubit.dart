import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

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
  int _searchSeq = 0;

  Future<void> search({bool reset = true}) async {
    if (isClosed) return;
    if (!reset && (state.isLoadingMore || !state.hasMore)) return;

    final seq = ++_searchSeq;
    var activeFilter = state.filters;

    if (reset) {
      if (activeFilter.range == TenantAuditRange.h24) {
        final refreshed = TenantAuditFilter.forRange(
          TenantAuditRange.h24,
          nowIct: VDateTime.toIct(_clockLocal()),
        );
        activeFilter = activeFilter.copyWith(
          fromLocal: refreshed.fromLocal,
          toLocal: refreshed.toLocal,
          exactFromUtc: refreshed.exactFromUtc,
          exactToUtc: refreshed.exactToUtc,
        );
      }
      emit(
        state.copyWith(
          status: IamLoadStatus.loading,
          filters: activeFilter,
          items: const [],
          totalCount: 0,
          clearNextCursor: true,
          clearFailure: true,
          clearLoadMoreFailure: true,
          isLoadingMore: false,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isLoadingMore: true,
          clearLoadMoreFailure: true,
        ),
      );
    }

    try {
      final trimmedQuery = activeFilter.query?.trim();
      final hasQuery = trimmedQuery != null && trimmedQuery.isNotEmpty;
      final matchingEventCodes = hasQuery
          ? TenantAuditEventCatalog.matchingEventCodes(trimmedQuery)
          : const <String>[];
      final effectiveQuery = hasQuery && matchingEventCodes.isEmpty ? trimmedQuery : null;
      final effectiveEventCodes = _mergeEventCodes(
        structured: activeFilter.eventCodes,
        derived: matchingEventCodes,
      );
      final fromUtc = activeFilter.exactFromUtc ??
          toUtcStartOfLocalDay(activeFilter.fromLocal);
      final toUtc = activeFilter.exactToUtc ??
          toUtcEndExclusiveOfLocalDay(activeFilter.toLocal);

      final page = await _auditLogs.search(
        from: fromUtc,
        to: toUtc,
        query: effectiveQuery,
        result: activeFilter.result?.code,
        eventCategory: activeFilter.eventCategory?.code,
        subjectType: activeFilter.subjectType,
        eventCodes: effectiveEventCodes,
        cursor: reset ? null : state.nextCursor,
      );
      if (isClosed || seq != _searchSeq) return;

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
          clearLoadMoreFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed || seq != _searchSeq) return;
      if (reset) {
        emit(
          state.copyWith(
            status: IamLoadStatus.failure,
            isLoadingMore: false,
            failure: IamUiFailureMapper.from(error),
          ),
        );
      } else {
        emit(
          state.copyWith(
            isLoadingMore: false,
            loadMoreFailure: IamUiFailureMapper.from(error),
          ),
        );
      }
    }
  }

  Future<void> loadNextPage() => search(reset: false);

  Future<void> applyFilter(TenantAuditFilter filter) async {
    if (isClosed) return;
    emit(state.copyWith(filters: filter));
    await search(reset: true);
  }

  Future<void> applyRangeAndResult(
    TenantAuditRange range,
    TenantAuditLogResult? result,
  ) async {
    final base = TenantAuditFilter.forRange(
      range,
      nowIct: VDateTime.toIct(_clockLocal()),
    );
    await applyFilter(
      base.copyWith(
        query: state.filters.query,
        result: result,
        clearResult: result == null,
        eventCategory: state.filters.eventCategory,
        subjectType: state.filters.subjectType,
        eventCodes: state.filters.eventCodes,
      ),
    );
  }

  Future<void> clearFilter() async {
    await applyFilter(
      TenantAuditFilter.forRange(
        TenantAuditRange.d30,
        nowIct: VDateTime.toIct(_clockLocal()),
      ),
    );
  }

  void clearLoadMoreFailure() {
    if (isClosed) return;
    emit(state.copyWith(clearLoadMoreFailure: true));
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
