import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../partner_startup.dart';
import 'inbox/process_inbox_command.dart';
import 'internal_commands/process_internal_commands_command.dart';

/// Partner bounded context messaging adapter for `messaging_worker`.
///
/// Delegates to the module composition root: recurring processing runs through
/// the `CommandBus` pipeline via [IPartnerModule.executeCommandAsync].
final class PartnerMessagingModule implements IMessagingModule {
  PartnerMessagingModule({required IPartnerModule module}) : _module = module;

  /// Builds the module composition root with service-role Supabase access.
  factory PartnerMessagingModule.create({
    required SupabaseClient supabase,
    ILoggerFactory? loggerFactory,
  }) {
    return PartnerMessagingModule(
      module: PartnerStartup.initializeForMessaging(
        supabase: supabase,
        loggerFactory: loggerFactory,
      ),
    );
  }

  final IPartnerModule _module;

  @override
  String get name => 'partner';

  @override
  Future<MessagingProcessResult> processMessagingOnce({
    required String tenantId,
    int batchSize = 10,
  }) async {
    final hadInboxWork = await _module.executeCommandAsync(
      ProcessInboxCommand(tenantId: tenantId, batchSize: batchSize),
    );
    final hadInternalWork = await _module.executeCommandAsync(
      ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: batchSize),
    );

    return MessagingProcessResult(
      hadInboxWork: hadInboxWork,
      hadInternalWork: hadInternalWork,
    );
  }
}
