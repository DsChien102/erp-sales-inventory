import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../domain/transaction_history/supabase_partner_transaction_history_write_gateway.dart';
import 'partner_inbox_processor.dart';
import 'partner_internal_command_processor.dart';
import 'partner_transaction_history_ingestor.dart';

/// Partner bounded context messaging adapter for `messaging_worker`.
final class PartnerMessagingModule implements IMessagingModule {
  PartnerMessagingModule({
    required PartnerInboxProcessor inboxProcessor,
    required PartnerInternalCommandProcessor internalCommandProcessor,
  })  : _inboxProcessor = inboxProcessor,
        _internalCommandProcessor = internalCommandProcessor;

  final PartnerInboxProcessor _inboxProcessor;
  final PartnerInternalCommandProcessor _internalCommandProcessor;

  @override
  String get name => 'partner';

  @override
  Future<MessagingProcessResult> processMessagingOnce({
    required String tenantId,
    int batchSize = 10,
  }) async {
    final hadInboxWork = await _inboxProcessor.processOnce(
      tenantId: tenantId,
      batchSize: batchSize,
    );
    final hadInternalWork = await _internalCommandProcessor.processOnce(
      tenantId: tenantId,
      batchSize: batchSize,
    );

    return MessagingProcessResult(
      hadInboxWork: hadInboxWork,
      hadInternalWork: hadInternalWork,
    );
  }
}

/// Builds [PartnerMessagingModule] with service-role Supabase access.
abstract final class PartnerMessagingModuleFactory {
  static PartnerMessagingModule create({
    required SupabaseClient supabase,
    ILoggerFactory? loggerFactory,
  }) {
    final resolvedLoggerFactory = loggerFactory ?? const NullLoggerFactory();
    final rpcClient = SupabaseSchemaRpcClient(
      supabase: supabase,
      schema: 'partner',
      mapError: (error, [stackTrace]) => RpcException(error.toString()),
      logger: resolvedLoggerFactory.named('partner.messaging.rpc'),
    );

    final writeGateway = SupabasePartnerTransactionHistoryWriteGateway(
      rpcClient: rpcClient,
    );
    final recordHandler = RecordPartnerTransactionHistoryCommandHandler(
      writeGateway: writeGateway,
    );
    final ingestor = PartnerTransactionHistoryIngestor(
      recordHandler: recordHandler,
    );

    return PartnerMessagingModule(
      inboxProcessor: PartnerInboxProcessor(
        rpcClient: rpcClient,
        ingestor: ingestor,
      ),
      internalCommandProcessor: PartnerInternalCommandProcessor(
        rpcClient: rpcClient,
        recordHandler: recordHandler,
      ),
    );
  }
}
