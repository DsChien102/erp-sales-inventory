import 'package:vet45_partner_domain/domain.dart';

/// Single row from partner_action_logs (audit read model).
final class PartnerActionLogItemDto {
  const PartnerActionLogItemDto({
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
  final DateTime createdAt;
  final String? reason;

  /// Partner detail snapshot before the action (nullable until the
  /// `get_partner_action_logs` draft returning snapshots is applied).
  final Map<String, dynamic>? beforeState;

  /// Partner detail snapshot after the action.
  final Map<String, dynamic>? afterState;
}
