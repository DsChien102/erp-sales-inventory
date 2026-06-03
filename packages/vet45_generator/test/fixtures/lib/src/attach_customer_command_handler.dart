import 'cqrs.dart';

class AttachCustomerCommand extends InternalCommandBase<void> {}

abstract class DraftRepository {}

final class AttachCustomerHandler
    implements ICommandHandler<AttachCustomerCommand, void> {
  AttachCustomerHandler({
    required DraftRepository draftRepository,
  });

  @override
  Future<void> handle(AttachCustomerCommand command) async {}
}
