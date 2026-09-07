import 'package:vet45_shared_application/application.dart';

/// Durable internal command for polling MISA issuance status (Slice 3b).
///
/// Dispatched to check status of an uncertain issuance attempt without republishing.
final class PollIssuanceStatusCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  PollIssuanceStatusCommand({
    String? id,
    required this.tenantId,
    required this.caseId,
    required this.attemptId,
    required this.correlationId,
    required this.checkOrdinal,
  }) : super(id);

  static const type = 'einvoice.poll_issuance_status';

  @override
  String get commandType => type;

  @override
  final String tenantId;
  final String caseId;
  final String attemptId;
  final String correlationId;
  final int checkOrdinal;

  @override
  Map<String, dynamic> toJson() {
    return stripInternalCommandRowId(<String, dynamic>{
      'tenant_id': tenantId,
      'case_id': caseId,
      'attempt_id': attemptId,
      'correlation_id': correlationId,
      'check_ordinal': checkOrdinal,
    });
  }

  factory PollIssuanceStatusCommand.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final n = normalizeInternalCommandDeserializeJson(json, rowId: id);
    return PollIssuanceStatusCommand(
      id: id,
      tenantId: n['tenant_id'] as String,
      caseId: n['case_id'] as String,
      attemptId: n['attempt_id'] as String,
      correlationId: n['correlation_id'] as String,
      checkOrdinal: n['check_ordinal'] as int? ?? 1,
    );
  }
}
