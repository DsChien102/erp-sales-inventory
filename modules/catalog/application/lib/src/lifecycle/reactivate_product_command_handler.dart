import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_command_gateway.dart';
import 'change_product_business_status_result.dart';
import 'reactivate_product_command.dart';

@CommandHandlerFor(ReactivateProductCommand)
final class ReactivateProductCommandHandler
    implements ICommandHandler<ReactivateProductCommand, ChangeProductBusinessStatusResult> {
  ReactivateProductCommandHandler({
    required IProductCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IProductCommandGateway _commandGateway;

  @override
  Future<ChangeProductBusinessStatusResult> handle(
    ReactivateProductCommand command,
  ) {
    return _commandGateway.reactivateProduct(command);
  }
}
