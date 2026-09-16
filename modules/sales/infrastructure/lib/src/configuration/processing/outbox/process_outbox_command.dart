import 'package:vet45_shared_application/application.dart';

final class ProcessOutboxCommand extends CommandBase<bool> implements IRecurringCommand {
  ProcessOutboxCommand({
    required this.tenantId,
    this.batchSize = 10,
    String? id,
  }) : super(id);

  final String tenantId;
  final int batchSize;
}
