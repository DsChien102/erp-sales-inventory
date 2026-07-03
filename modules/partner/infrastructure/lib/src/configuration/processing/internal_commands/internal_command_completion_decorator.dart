import 'package:vet45_shared_application/application.dart';

import 'i_partner_internal_command_client.dart';
import 'partner_internal_command_claim_scope.dart';

final class InternalCommandCompletionDecorator<
  TCommand extends InternalCommandBase<void>
> {
  InternalCommandCompletionDecorator({
    required Future<void> Function(TCommand command) inner,
    required IPartnerInternalCommandClient commandClient,
  })  : _inner = inner,
        _commandClient = commandClient;

  final Future<void> Function(TCommand command) _inner;
  final IPartnerInternalCommandClient _commandClient;

  Future<void> handle(TCommand command) async {
    final claim = PartnerInternalCommandClaimScope.current;
    if (claim == null) {
      await _inner(command);
      return;
    }

    try {
      await _inner(command);
      await _commandClient.complete(
        tenantId: claim.tenantId,
        commandId: command.id,
        claimToken: claim.claimToken,
      );
    } catch (error) {
      await _commandClient.fail(
        tenantId: claim.tenantId,
        commandId: command.id,
        claimToken: claim.claimToken,
        error: error.toString(),
      );
      rethrow;
    }
  }
}
