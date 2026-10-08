/// Audit action types recorded in partner_action_logs.
enum PartnerActionType {
  create,
  update,
  addContact,
  removeContact,
  transform,
  deactivate,
  reactivate,
  delete;

  /// Parses wire values (`add_contact`) or Dart names (`addContact`).
  static PartnerActionType parse(String raw) {
    return switch (raw) {
      'create' => PartnerActionType.create,
      'update' => PartnerActionType.update,
      'add_contact' || 'addContact' => PartnerActionType.addContact,
      'remove_contact' || 'removeContact' => PartnerActionType.removeContact,
      'transform' => PartnerActionType.transform,
      'deactivate' => PartnerActionType.deactivate,
      'reactivate' => PartnerActionType.reactivate,
      'delete' => PartnerActionType.delete,
      _ => throw ArgumentError.value(raw, 'raw', 'Unknown partner action type'),
    };
  }
}

class PartnerActionLog {
  const PartnerActionLog({
    required this.actionLogId,
    required this.actionType,
    required this.actorUserId,
    required this.createdAt,
    this.reason,
    this.beforeState,
    this.afterState,
  });

  final String actionLogId;
  final PartnerActionType actionType;
  final String actorUserId;
  final String? reason;
  final Map<String, dynamic>? beforeState;
  final Map<String, dynamic>? afterState;
  final DateTime createdAt;

  factory PartnerActionLog.fromJson(Map<String, dynamic> json) {
    return PartnerActionLog(
      actionLogId: json['action_log_id'] as String,
      actionType: PartnerActionType.parse(json['action_type'] as String),
      actorUserId: json['actor_user_id'] as String,
      reason: json['reason'] as String?,
      beforeState: _asStateMap(json['before_state']),
      afterState: _asStateMap(json['after_state']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class PartnerActionLogPage {
  const PartnerActionLogPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<PartnerActionLog> items;
  final int total;
  final int page;
  final int limit;

  factory PartnerActionLogPage.fromJson(Map<String, dynamic> row) {
    final items = (row['items'] as List? ?? const [])
        .map((item) => PartnerActionLog.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
    return PartnerActionLogPage(
      items: items,
      total: row['total'] as int? ?? items.length,
      page: row['page'] as int? ?? 1,
      limit: row['limit'] as int? ?? items.length,
    );
  }
}

/// Snapshots are absent until the states draft RPC is applied; `{}` from
/// `_log_partner_action` defaults is normalized to null (no diff data).
Map<String, dynamic>? _asStateMap(Object? raw) {
  if (raw is! Map || raw.isEmpty) return null;
  return Map<String, dynamic>.from(raw);
}
