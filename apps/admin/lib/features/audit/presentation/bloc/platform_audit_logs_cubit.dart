import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../mappers/platform_audit_ui_mapper.dart';
import 'platform_audit_logs_state.dart';

final class PlatformAuditLogsCubit extends Cubit<PlatformAuditLogsState> {
  PlatformAuditLogsCubit({
    required IIamModule iamModule,
    PlatformAuditLogsState? initialState,
  }) : _iamModule = iamModule,
       super(initialState ?? const PlatformAuditLogsState());

  final IIamModule _iamModule;

  Future<void> load({String? query}) async {
    if (isClosed) return;
    final nextQuery = query ?? state.searchQuery;
    emit(
      state.copyWith(
        status: PlatformAuditLogsStatus.loading,
        searchQuery: nextQuery,
        clearError: true,
      ),
    );

    try {
      final page = await _iamModule
          .executeQueryAsync<CursorPageDto<PlatformAuditLogSummaryDto>>(
            SearchPlatformAuditLogsQuery(
              action: nextQuery.trim().isEmpty ? null : nextQuery.trim(),
            ),
          );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlatformAuditLogsStatus.success,
          logs: page.items.map(PlatformAuditUiMapper.fromSummary).toList(),
          clearError: true,
        ),
      );
    } on ApplicationException catch (e) {
      if (isClosed) return;
      final unauthorized = e.message.contains('PLATFORM_PERMISSION_DENIED');
      emit(
        state.copyWith(
          status: unauthorized
              ? PlatformAuditLogsStatus.unauthorized
              : PlatformAuditLogsStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlatformAuditLogsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setFilterCriteria(AuditLogFilterCriteria criteria) {
    emit(state.copyWith(filterCriteria: criteria));
  }

  Future<AuditLogItemUiModel?> loadDetail(String auditLogId) async {
    final id = auditLogId.startsWith('#')
        ? auditLogId.substring(1)
        : auditLogId;
    try {
      final detail = await _iamModule
          .executeQueryAsync<PlatformAuditLogDetailDto>(
            GetPlatformAuditLogQuery(auditLogId: id),
          );
      return PlatformAuditUiMapper.fromDetail(detail);
    } catch (_) {
      return null;
    }
  }
}
