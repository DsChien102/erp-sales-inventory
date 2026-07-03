import 'package:vet45_shared_application/application.dart';

import '../../ports/i_partner_transaction_history_write_gateway.dart';
import 'record_partner_transaction_history_command.dart';

final class RecordPartnerTransactionHistoryCommandHandler
    implements ICommandHandler<RecordPartnerTransactionHistoryCommand, void> {
  RecordPartnerTransactionHistoryCommandHandler({
    required IPartnerTransactionHistoryWriteGateway writeGateway,
  }) : _writeGateway = writeGateway;

  final IPartnerTransactionHistoryWriteGateway _writeGateway;

  @override
  Future<void> handle(RecordPartnerTransactionHistoryCommand command) {
    return _writeGateway.upsert(command);
  }
}
