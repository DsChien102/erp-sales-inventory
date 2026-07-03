import '../transaction_history/record_transaction_history/record_partner_transaction_history_command.dart';

abstract interface class IPartnerTransactionHistoryWriteGateway {
  Future<void> upsert(RecordPartnerTransactionHistoryCommand command);
}
