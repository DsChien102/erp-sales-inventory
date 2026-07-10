import '../partner_history/commands/record_partner_history/record_partner_history_command.dart';

/// Partner history write port — internal projection upsert.
abstract interface class IPartnerHistoryWriteGateway {
  Future<void> upsertPartnerHistory(RecordPartnerHistoryCommand command);
}
