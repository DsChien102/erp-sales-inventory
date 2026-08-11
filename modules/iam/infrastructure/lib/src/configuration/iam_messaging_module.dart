import 'package:vet45_adapters/vet45_adapters.dart';

import '../configuration/processing/commands_executor.dart';
import '../configuration/processing/inbox/process_inbox_command.dart';
import '../configuration/processing/internal_commands/process_internal_commands_command.dart';
import '../configuration/processing/outbox/process_outbox_command.dart';

/// Thin worker adapter: outbox → inbox → internal via Process* commands.
final class IamMessagingModule implements IMessagingModule {
  const IamMessagingModule();

  @override
  String get name => 'iam';

  @override
  Future<MessagingProcessResult> processMessagingOnce({
    required String tenantId,
    int batchSize = 10,
  }) {
    return IamStartupMessaging.processMessagingOnce(
      tenantId: tenantId,
      batchSize: batchSize,
    );
  }
}

/// Shared processMessagingOnce entry used by [IamMessagingModule] and tests.
abstract final class IamStartupMessaging {
  static Future<MessagingProcessResult> processMessagingOnce({
    required String tenantId,
    int batchSize = 10,
  }) async {
    final outbox = await CommandsExecutor.execute(
      ProcessOutboxCommand(tenantId: tenantId, batchSize: batchSize),
    );
    final inbox = await CommandsExecutor.execute(
      ProcessInboxCommand(tenantId: tenantId, batchSize: batchSize),
    );
    final internal = await CommandsExecutor.execute(
      ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: batchSize),
    );
    return MessagingProcessResult(
      hadOutboxWork: outbox,
      hadInboxWork: inbox,
      hadInternalWork: internal,
    );
  }
}
