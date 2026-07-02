import 'package:vet45_shared_application/application.dart';

/// Recurring command: drains `partner.internal_commands` for one tenant.
final class ProcessInternalCommandsCommand extends CommandBase<bool>
    implements IRecurringCommand {
  ProcessInternalCommandsCommand({
    required this.tenantId,
    this.batchSize = 10,
    String? id,
  }) : super(id);

  final String tenantId;
  final int batchSize;
}
