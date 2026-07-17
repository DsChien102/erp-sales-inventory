import 'package:vet45_partner_domain/domain.dart';

/// Single row from partner_action_logs (audit read model).
final class PartnerActionLogItemDto {
  const PartnerActionLogItemDto({
    required this.actionLogId,
    required this.actionType,
    required this.actorUserId,
    required this.createdAt,
    this.reason,
  });

  final String actionLogId;
  final PartnerActionType actionType;
  final String actorUserId;
  final DateTime createdAt;
  final String? reason;
}
