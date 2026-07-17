import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'configuration/pricing_composition_root.dart';
import 'configuration/processing/pricing_query_access_guard.dart';

final class PricingModule implements IPricingModule {
  const PricingModule({
    required IExecutionContext executionContext,
    required PricingQueryAccessGuard queryAccessGuard,
  }) : _executionContext = executionContext,
       _queryAccessGuard = queryAccessGuard;

  final IExecutionContext _executionContext;
  final PricingQueryAccessGuard _queryAccessGuard;

  @override
  Future<TResult> executeCommandAsync<TResult>(
    ICommand<TResult> command,
  ) async {
    final effectiveCommand = await _bindExecutionContext(command);
    return ScopedCommandExecutor.executeCommand(
      command: effectiveCommand,
      lifetimeScope: PricingCompositionRoot.beginLifetimeScope,
      scopeNamePrefix: 'pricing-command',
    );
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    final effectiveQuery = await _queryAccessGuard.bindAndAuthorize(query);
    return ScopedCommandExecutor.executeQuery(
      query: effectiveQuery,
      lifetimeScope: PricingCompositionRoot.beginLifetimeScope,
    );
  }

  Future<ICommand<TResult>> _bindExecutionContext<TResult>(
    ICommand<TResult> command,
  ) async {
    if (command is CreateCustomerPriceRuleCommand) {
      final createCommand = command as CreateCustomerPriceRuleCommand;
      try {
        return createCommand.withExecutionContext(
              tenantId: await _executionContext.requireTenantId(),
              actorId: await _executionContext.requireUserId(),
            )
            as ICommand<TResult>;
      } on ApplicationException {
        throw const PricingBlockedException(
          PricingBlockedCodes.noPermission,
          message: 'Execution context is required.',
        );
      }
    }
    if (command is UpdateCustomerPriceRuleCommand) {
      final updateCommand = command as UpdateCustomerPriceRuleCommand;
      try {
        return updateCommand.withExecutionContext(
              tenantId: await _executionContext.requireTenantId(),
              actorId: await _executionContext.requireUserId(),
            )
            as ICommand<TResult>;
      } on ApplicationException {
        throw const PricingBlockedException(
          PricingBlockedCodes.noPermission,
          message: 'Execution context is required.',
        );
      }
    }
    if (command is DisableCustomerPriceRuleCommand) {
      final disableCommand = command as DisableCustomerPriceRuleCommand;
      try {
        return disableCommand.withExecutionContext(
              tenantId: await _executionContext.requireTenantId(),
              actorId: await _executionContext.requireUserId(),
            )
            as ICommand<TResult>;
      } on ApplicationException {
        throw const PricingBlockedException(
          PricingBlockedCodes.noPermission,
          message: 'Execution context is required.',
        );
      }
    }
    if (command is ReenableCustomerPriceRuleCommand) {
      final reenableCommand = command as ReenableCustomerPriceRuleCommand;
      try {
        return reenableCommand.withExecutionContext(
              tenantId: await _executionContext.requireTenantId(),
              actorId: await _executionContext.requireUserId(),
            )
            as ICommand<TResult>;
      } on ApplicationException {
        throw const PricingBlockedException(
          PricingBlockedCodes.noPermission,
          message: 'Execution context is required.',
        );
      }
    }
    if (command is StartCustomerPriceRuleImportCommand) {
      final startCommand = command as StartCustomerPriceRuleImportCommand;
      try {
        return startCommand.withExecutionContext(
              tenantId: await _executionContext.requireTenantId(),
              actorId: await _executionContext.requireUserId(),
            )
            as ICommand<TResult>;
      } on ApplicationException {
        throw const PricingBlockedException(
          PricingBlockedCodes.noPermission,
          message: 'Execution context is required.',
        );
      }
    }
    if (command is ConfirmCustomerPriceRuleImportCommand) {
      final confirmCommand = command as ConfirmCustomerPriceRuleImportCommand;
      try {
        return confirmCommand.withExecutionContext(
              tenantId: await _executionContext.requireTenantId(),
              actorId: await _executionContext.requireUserId(),
            )
            as ICommand<TResult>;
      } on ApplicationException {
        throw const PricingBlockedException(
          PricingBlockedCodes.noPermission,
          message: 'Execution context is required.',
        );
      }
    }
    if (command is CancelCustomerPriceRuleImportCommand) {
      final cancelCommand = command as CancelCustomerPriceRuleImportCommand;
      try {
        return cancelCommand.withExecutionContext(
              tenantId: await _executionContext.requireTenantId(),
              actorId: await _executionContext.requireUserId(),
            )
            as ICommand<TResult>;
      } on ApplicationException {
        throw const PricingBlockedException(
          PricingBlockedCodes.noPermission,
          message: 'Execution context is required.',
        );
      }
    }
    if (command is SaveRememberedPriceFromOrderCommand) {
      final memoryCommand = command as SaveRememberedPriceFromOrderCommand;
      try {
        return memoryCommand.withExecutionContext(
              tenantId: await _executionContext.requireTenantId(),
              actorId: await _executionContext.requireUserId(),
            )
            as ICommand<TResult>;
      } on ApplicationException {
        throw const PricingBlockedException(
          PricingBlockedCodes.noPermission,
          message: 'Execution context is required.',
        );
      }
    }
    return command;
  }
}
