import 'cqrs.dart';

class CheckoutCommand implements ICommand<String> {
  @override
  String get id => 'id';
}

final class CheckoutCommandValidator implements ICommandValidator<CheckoutCommand> {
  @override
  Future<void> validate(CheckoutCommand command) async {}
}
