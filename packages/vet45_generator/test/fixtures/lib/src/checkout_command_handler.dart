import 'cqrs.dart';

class CheckoutCommand implements ICommand<String> {
  @override
  String get id => 'id';
}

abstract class DraftRepository {}

abstract class CommandGateway {}

abstract class ProductLookup {}

final class CheckoutHandler implements ICommandHandler<CheckoutCommand, String> {
  CheckoutHandler({
    required this.draftRepository,
    required this.commandGateway,
    required this.productLookup,
    Object uuid = const Object(),
  });

  final DraftRepository draftRepository;
  final CommandGateway commandGateway;
  final ProductLookup productLookup;

  @override
  Future<String> handle(CheckoutCommand command) async => 'ok';
}
