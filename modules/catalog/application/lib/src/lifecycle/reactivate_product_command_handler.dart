import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_command_gateway.dart';
import 'change_product_business_status_result.dart';
import 'reactivate_product_command.dart';
import 'reactivate_product_command_validator.dart';

@CommandHandlerFor(ReactivateProductCommand)
final class ReactivateProductCommandHandler
    implements ICommandHandler<ReactivateProductCommand, ChangeProductBusinessStatusResult> {
  ReactivateProductCommandHandler({
    required IProductCommandGateway commandGateway,
    ReactivateProductCommandValidator? validator,
  }) : _commandGateway = commandGateway,
       _validator = validator ?? ReactivateProductCommandValidator();

  final IProductCommandGateway _commandGateway;
  final ReactivateProductCommandValidator _validator;

  @override
  Future<ChangeProductBusinessStatusResult> handle(
    ReactivateProductCommand command,
  ) async {
    await _validator.validate(command);
    return _commandGateway.reactivateProduct(command);
  }
}
