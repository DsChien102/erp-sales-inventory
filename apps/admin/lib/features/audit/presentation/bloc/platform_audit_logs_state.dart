import 'package:vet45_iam_presentation/presentation.dart';

enum PlatformAuditLogsStatus {
  initial,
  loading,
  success,
  failure,
  unauthorized,
}

final class PlatformAuditLogsState {
  const PlatformAuditLogsState({
    this.status = PlatformAuditLogsStatus.initial,
    this.logs = const [],
    this.searchQuery = '',
    this.filterCriteria = const AuditLogFilterCriteria(),
    this.errorMessage,
  });

  final PlatformAuditLogsStatus status;
  final List<AuditLogItemUiModel> logs;
  final String searchQuery;
  final AuditLogFilterCriteria filterCriteria;
  final String? errorMessage;

  List<AuditLogItemUiModel> get filteredLogs {
    return logs.where((log) {
      if (filterCriteria.status != null &&
          log.status != filterCriteria.status) {
        return false;
      }
      if (filterCriteria.actorType != 'Tất cả') {
        if (filterCriteria.actorType == 'Người dùng' &&
            log.actorRole.contains('Hệ thống')) {
          return false;
        }
        if (filterCriteria.actorType == 'Hệ thống' &&
            !log.actorRole.contains('Hệ thống')) {
          return false;
        }
      }
      final q = searchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        return log.title.toLowerCase().contains(q) ||
            log.actorName.toLowerCase().contains(q) ||
            log.targetOrg.toLowerCase().contains(q) ||
            log.actionCode.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  PlatformAuditLogsState copyWith({
    PlatformAuditLogsStatus? status,
    List<AuditLogItemUiModel>? logs,
    String? searchQuery,
    AuditLogFilterCriteria? filterCriteria,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlatformAuditLogsState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      searchQuery: searchQuery ?? this.searchQuery,
      filterCriteria: filterCriteria ?? this.filterCriteria,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
