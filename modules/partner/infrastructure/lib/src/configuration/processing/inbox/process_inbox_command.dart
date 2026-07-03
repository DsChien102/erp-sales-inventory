import 'package:vet45_shared_application/application.dart';

/// Recurring command: drains `partner.inbox_messages` for one tenant.
final class ProcessInboxCommand extends CommandBase<bool>
    implements IRecurringCommand {
  ProcessInboxCommand({
    required this.tenantId,
    this.batchSize = 10,
    String? id,
  }) : super(id);

  final String tenantId;
  final int batchSize;
}
