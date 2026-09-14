import '../../shared/return_exchange_draft_dto.dart';
import '../../shared/return_exchange_result_dto.dart';
import '../commands/cancel_return_exchange/cancel_return_exchange_command.dart';
import '../commands/complete_return_exchange/complete_return_exchange_command.dart';
import '../commands/confirm_return_exchange/confirm_return_exchange_command.dart';
import '../commands/start_return_exchange/start_return_exchange_command.dart';
import '../commands/update_return_exchange/update_return_exchange_command.dart';
import 'i_return_exchange_reference_port.dart';

abstract interface class IReturnExchangeCommandGateway {
  Future<ReturnExchangeDraftDto> start(
    StartReturnExchangeCommand command, {
    required ReturnExchangeReferenceDecision referenceDecision,
  });

  Future<ReturnExchangeDraftDto> update(
    UpdateReturnExchangeCommand command, {
    required ReturnExchangeReferenceDecision referenceDecision,
  });

  Future<ReturnExchangeResultDto> cancel(
    CancelReturnExchangeCommand command,
  );

  Future<ReturnExchangeResultDto> confirm(
    ConfirmReturnExchangeCommand command, {
    required ReturnExchangeReferenceDecision referenceDecision,
  });

  Future<ReturnExchangeResultDto> complete(
    CompleteReturnExchangeCommand command,
  );
}
