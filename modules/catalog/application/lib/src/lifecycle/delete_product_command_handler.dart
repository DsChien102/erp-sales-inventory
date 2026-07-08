import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_command_gateway.dart';
import 'change_product_soft_delete_result.dart';
import 'delete_product_command.dart';
import 'delete_product_command_validator.dart';

@CommandHandlerFor(DeleteProductCommand)
final class DeleteProductCommandHandler
    implements ICommandHandler<DeleteProductCommand, ChangeProductSoftDeleteResult> {
  DeleteProductCommandHandler({
    required IProductCommandGateway commandGateway,
    DeleteProductCommandValidator? validator,
  }) : _commandGateway = commandGateway,
       _validator = validator ?? DeleteProductCommandValidator();

  final IProductCommandGateway _commandGateway;
  final DeleteProductCommandValidator _validator;

  @override
  Future<ChangeProductSoftDeleteResult> handle(
    DeleteProductCommand command,
  ) async {
    await _validator.validate(command);
    return _commandGateway.deleteProduct(command);
  }
}
