import 'package:equatable/equatable.dart';

import 'partner_action_log_diff.dart';

enum PartnerChangeHistoryStatus {
  initial,
  loading,
  success,
  failure,
}

class PartnerChangeHistoryEntry extends Equatable {
  final String id;
  final DateTime occurredAt;
  final String actorDisplayName;
  final String changeType;
  final String summary;
  final String? reason;
  final List<PartnerFieldChange> changes;

  const PartnerChangeHistoryEntry({
    required this.id,
    required this.occurredAt,
    required this.actorDisplayName,
    required this.changeType,
    required this.summary,
    this.reason,
    this.changes = const [],
  });

  @override
  List<Object?> get props => [
    id,
    occurredAt,
    actorDisplayName,
    changeType,
    summary,
    reason,
    changes,
  ];
}

class PartnerChangeHistoryState extends Equatable {
  const PartnerChangeHistoryState({
    this.status = PartnerChangeHistoryStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final PartnerChangeHistoryStatus status;
  final List<PartnerChangeHistoryEntry> items;
  final String? errorMessage;

  PartnerChangeHistoryState copyWith({
    PartnerChangeHistoryStatus? status,
    List<PartnerChangeHistoryEntry>? items,
    String? errorMessage,
  }) {
    return PartnerChangeHistoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
