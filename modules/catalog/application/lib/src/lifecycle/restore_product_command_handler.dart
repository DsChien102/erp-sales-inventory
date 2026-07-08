import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_command_gateway.dart';
import 'change_product_soft_delete_result.dart';
import 'restore_product_command.dart';
import 'restore_product_command_validator.dart';

@CommandHandlerFor(RestoreProductCommand)
final class RestoreProductCommandHandler
    implements ICommandHandler<RestoreProductCommand, ChangeProductSoftDeleteResult> {
  RestoreProductCommandHandler({
    required IProductCommandGateway commandGateway,
    RestoreProductCommandValidator? validator,
  }) : _commandGateway = commandGateway,
       _validator = validator ?? RestoreProductCommandValidator();

  final IProductCommandGateway _commandGateway;
  final RestoreProductCommandValidator _validator;

  @override
  Future<ChangeProductSoftDeleteResult> handle(
    RestoreProductCommand command,
  ) async {
    await _validator.validate(command);
    return _commandGateway.restoreProduct(command);
  }
}
