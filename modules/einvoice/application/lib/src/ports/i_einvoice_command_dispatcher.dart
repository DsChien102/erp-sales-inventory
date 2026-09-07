import 'package:vet45_shared_application/application.dart';

abstract interface class IEinvoiceCommandDispatcher {
  Future<TResult> execute<TResult>(ICommand<TResult> command);
}
