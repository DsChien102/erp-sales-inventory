import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_partner_history_write_gateway.dart';
import 'record_partner_history_command.dart';

@CommandHandlerFor(RecordPartnerHistoryCommand)
final class RecordPartnerHistoryCommandHandler
    implements ICommandHandler<RecordPartnerHistoryCommand, void> {
  RecordPartnerHistoryCommandHandler({
    required IPartnerHistoryWriteGateway historyWriteGateway,
  }) : _historyWriteGateway = historyWriteGateway;

  final IPartnerHistoryWriteGateway _historyWriteGateway;

  @override
  Future<void> handle(RecordPartnerHistoryCommand command) {
    return _historyWriteGateway.upsertPartnerHistory(command);
  }
}
