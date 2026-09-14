import '../return_exchange_order/commands/cancel_return_exchange/cancel_return_exchange_command.dart';
import '../return_exchange_order/commands/complete_return_exchange/complete_return_exchange_command.dart';
import '../return_exchange_order/commands/confirm_return_exchange/confirm_return_exchange_command.dart';
import '../return_exchange_order/commands/start_return_exchange/start_return_exchange_command.dart';
import '../return_exchange_order/commands/update_return_exchange/update_return_exchange_command.dart';
import '../return_exchange_order/ports/i_return_exchange_command_gateway.dart';
import '../return_exchange_order/ports/i_return_exchange_reference_port.dart';
import '../shared/return_exchange_draft_dto.dart';
import '../shared/return_exchange_result_dto.dart';
import '../shared/sales_contract_enums.dart';

final class FakeReturnExchangeCommandGateway implements IReturnExchangeCommandGateway {
  FakeReturnExchangeCommandGateway({
    ReturnExchangeDraftDto? startResult,
    ReturnExchangeDraftDto? updateResult,
    ReturnExchangeResultDto? cancelResult,
    ReturnExchangeResultDto? confirmResult,
    ReturnExchangeResultDto? completeResult,
    this.error,
  }) : _startResult = startResult,
       _updateResult = updateResult,
       _cancelResult = cancelResult,
       _confirmResult = confirmResult,
       _completeResult = completeResult;

  final ReturnExchangeDraftDto? _startResult;
  final ReturnExchangeDraftDto? _updateResult;
  final ReturnExchangeResultDto? _cancelResult;
  final ReturnExchangeResultDto? _confirmResult;
  final ReturnExchangeResultDto? _completeResult;
  final Object? error;

  int startCalls = 0;
  int updateCalls = 0;
  int cancelCalls = 0;
  int confirmCalls = 0;
  int completeCalls = 0;

  StartReturnExchangeCommand? lastStartCommand;
  UpdateReturnExchangeCommand? lastUpdateCommand;
  CancelReturnExchangeCommand? lastCancelCommand;
  ConfirmReturnExchangeCommand? lastConfirmCommand;
  CompleteReturnExchangeCommand? lastCompleteCommand;
  ReturnExchangeReferenceDecision? lastStartDecision;
  ReturnExchangeReferenceDecision? lastUpdateDecision;
  ReturnExchangeReferenceDecision? lastConfirmDecision;

  @override
  Future<ReturnExchangeDraftDto> start(
    StartReturnExchangeCommand command, {
    required ReturnExchangeReferenceDecision referenceDecision,
  }) async {
    startCalls += 1;
    lastStartCommand = command;
    lastStartDecision = referenceDecision;
    if (error != null) throw error!;
    return _startResult ??
        ReturnExchangeDraftDto(
          returnExchangeId: 'return-1',
          salesOrderId: command.salesOrderId,
          version: 1,
          status: ReturnExchangeStatus.draft,
          lines: command.lines,
        );
  }

  @override
  Future<ReturnExchangeDraftDto> update(
    UpdateReturnExchangeCommand command, {
    required ReturnExchangeReferenceDecision referenceDecision,
  }) async {
    updateCalls += 1;
    lastUpdateCommand = command;
    lastUpdateDecision = referenceDecision;
    if (error != null) throw error!;
    return _updateResult ??
        ReturnExchangeDraftDto(
          returnExchangeId: command.returnExchangeId,
          salesOrderId: 'order-1',
          version: command.expectedVersion + 1,
          status: ReturnExchangeStatus.draft,
          lines: command.lines,
        );
  }

  @override
  Future<ReturnExchangeResultDto> cancel(
    CancelReturnExchangeCommand command,
  ) async {
    cancelCalls += 1;
    lastCancelCommand = command;
    if (error != null) throw error!;
    return _cancelResult ??
        ReturnExchangeResultDto(
          returnExchangeId: command.returnExchangeId,
          salesOrderId: 'order-1',
          version: (command.expectedVersion ?? 1) + 1,
          status: ReturnExchangeStatus.cancelled,
        );
  }

  @override
  Future<ReturnExchangeResultDto> confirm(
    ConfirmReturnExchangeCommand command, {
    required ReturnExchangeReferenceDecision referenceDecision,
  }) async {
    confirmCalls += 1;
    lastConfirmCommand = command;
    lastConfirmDecision = referenceDecision;
    if (error != null) throw error!;
    return _confirmResult ??
        ReturnExchangeResultDto(
          returnExchangeId: command.returnExchangeId,
          salesOrderId: 'order-1',
          version: command.expectedVersion + 1,
          status: ReturnExchangeStatus.confirmed,
        );
  }

  @override
  Future<ReturnExchangeResultDto> complete(
    CompleteReturnExchangeCommand command,
  ) async {
    completeCalls += 1;
    lastCompleteCommand = command;
    if (error != null) throw error!;
    return _completeResult ??
        ReturnExchangeResultDto(
          returnExchangeId: command.returnExchangeId,
          salesOrderId: 'order-1',
          version: command.expectedVersion + 1,
          status: ReturnExchangeStatus.completed,
        );
  }
}
