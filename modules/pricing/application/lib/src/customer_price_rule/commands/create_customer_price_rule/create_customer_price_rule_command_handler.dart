import 'package:uuid/uuid.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_customer_price_rule_command_gateway.dart';
import '../../../ports/i_customer_price_rule_create_context_port.dart';
import '../../../shared/pricing_blocked_codes.dart';
import '../../../shared/pricing_blocked_exception.dart';
import '../../shared/customer_price_rule_create_context.dart';
import 'create_customer_price_rule_command.dart';
import 'create_customer_price_rule_result.dart';

@CommandHandlerFor(CreateCustomerPriceRuleCommand)
final class CreateCustomerPriceRuleCommandHandler
    implements
        ICommandHandler<
          CreateCustomerPriceRuleCommand,
          CreateCustomerPriceRuleResult
        > {
  CreateCustomerPriceRuleCommandHandler({
    required ICustomerPriceRuleCreateContextPort createContextPort,
    required ICustomerPriceRuleCommandGateway commandGateway,
  }) : _createContextPort = createContextPort,
       _commandGateway = commandGateway;

  final ICustomerPriceRuleCreateContextPort _createContextPort;
  final ICustomerPriceRuleCommandGateway _commandGateway;

  @override
  Future<CreateCustomerPriceRuleResult> handle(
    CreateCustomerPriceRuleCommand command,
  ) async {
    final context = await _createContextPort.load(command);
    final isIdempotentRetry = context.idempotencyKeyExists;
    if (!isIdempotentRetry && context.hasConflictingRule) {
      throw PricingBlockedException(
        PricingBlockedCodes.duplicateActiveRule,
        message: 'An active customer price rule already overlaps this period.',
        details: {
          if (context.conflictingRuleId != null)
            'conflictingRuleId': context.conflictingRuleId,
        },
      );
    }
    if (!isIdempotentRetry) {
      _ensureReferencesAreValid(command, context);
    }
    if (!isIdempotentRetry &&
        context.productUnit.isBelowFloor &&
        (!command.acknowledgeFloorWarning || !context.canOverrideFloor)) {
      final reason = command.acknowledgeFloorWarning
          ? 'overridePermissionRequired'
          : 'acknowledgementRequired';
      throw PricingBlockedException(
        PricingBlockedCodes.belowFloorBlocked,
        message: 'Customer price is below the current floor.',
        details: {'reason': reason},
      );
    }

    final price = Money(
      amountMinor: command.rulePriceMinor,
      currencyCode: command.currencyCode,
    );
    final outcome = isIdempotentRetry
        ? RuleValidationOutcome.clear()
        : RuleValidationOutcome.evaluateFloor(
            rulePrice: price,
            listPrice: _snapshotMoney(
              context.productUnit.listPriceMinor,
              context.productUnit.currencyCode,
            ),
            floorPrice: _snapshotMoney(
              context.productUnit.floorPriceMinor,
              context.productUnit.currencyCode,
            ),
            floorPriceHidden: context.productUnit.floorPriceHidden,
            acknowledgeFloorWarning: command.acknowledgeFloorWarning,
            canOverrideFloor: context.canOverrideFloor,
          );
    if (outcome.isBlocked) {
      final currencyMismatch = outcome.blockingCodes.contains(
        'currency_mismatch',
      );
      throw PricingBlockedException(
        currencyMismatch
            ? PricingBlockedCodes.referenceInvalid
            : PricingBlockedCodes.belowFloorBlocked,
        message: 'Customer price rule validation is blocked.',
        details: {
          'blockingCodes': outcome.blockingCodes,
          if (!currencyMismatch)
            'reason':
                outcome.blockingCodes.contains('override_permission_required')
                ? 'overridePermissionRequired'
                : 'acknowledgementRequired',
        },
      );
    }

    final candidate = CustomerPriceRule.createManual(
      id: const Uuid().v4(),
      key: CustomerPriceRuleKey(
        tenantId: command.tenantId,
        customerId: command.customerId,
        productId: command.productId,
        productUnitId: command.productUnitId,
      ),
      price: price,
      effectivePeriod: EffectivePeriod(
        effectiveFrom: command.effectiveFrom,
        effectiveTo: command.effectiveTo,
      ),
      actorId: command.actorId,
      validationOutcome: outcome,
      note: command.note,
    );
    return _commandGateway.create(
      candidate: candidate,
      idempotencyKey: command.idempotencyKey,
      acknowledgeFloorWarning: command.acknowledgeFloorWarning,
    );
  }

  void _ensureReferencesAreValid(
    CreateCustomerPriceRuleCommand command,
    CustomerPriceRuleCreateContext context,
  ) {
    final product = context.productUnit;
    final valid =
        context.customer.isValidForTransaction &&
        product.isSellable &&
        product.productId == command.productId &&
        product.productUnitId == command.productUnitId &&
        product.currencyCode.toUpperCase() ==
            command.currencyCode.toUpperCase();
    if (!valid) {
      throw const PricingBlockedException(
        PricingBlockedCodes.referenceInvalid,
        message: 'Customer, product, or selling unit is no longer valid.',
      );
    }
  }

  Money? _snapshotMoney(int? amountMinor, String currencyCode) {
    if (amountMinor == null || amountMinor <= 0) {
      return null;
    }
    return Money(amountMinor: amountMinor, currencyCode: currencyCode);
  }
}
