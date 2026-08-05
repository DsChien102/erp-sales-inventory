import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_customer_price_rule_command_gateway.dart';
import '../../../ports/i_customer_price_rule_update_context_port.dart';
import '../../../shared/pricing_blocked_codes.dart';
import '../../../shared/pricing_blocked_exception.dart';
import '../../shared/customer_price_rule_detail_dto.dart';
import '../../shared/customer_price_rule_update_context.dart';
import 'update_customer_price_rule_command.dart';

@CommandHandlerFor(UpdateCustomerPriceRuleCommand)
final class UpdateCustomerPriceRuleCommandHandler
    implements
        ICommandHandler<
          UpdateCustomerPriceRuleCommand,
          CustomerPriceRuleDetailDto
        > {
  UpdateCustomerPriceRuleCommandHandler({
    required ICustomerPriceRuleUpdateContextPort updateContextPort,
    required ICustomerPriceRuleCommandGateway commandGateway,
  }) : _updateContextPort = updateContextPort,
       _commandGateway = commandGateway;

  final ICustomerPriceRuleUpdateContextPort _updateContextPort;
  final ICustomerPriceRuleCommandGateway _commandGateway;

  @override
  Future<CustomerPriceRuleDetailDto> handle(
    UpdateCustomerPriceRuleCommand command,
  ) async {
    final context = await _updateContextPort.load(command);
    final current = context.currentRule;
    if (current.version != command.expectedVersion) {
      throw const PricingBlockedException(PricingBlockedCodes.stateChanged);
    }

    final price = Money(
      amountMinor: command.rulePriceMinor,
      currencyCode: current.price.currencyCode,
    );
    final period = EffectivePeriod(
      effectiveFrom: command.effectiveFrom,
      effectiveTo: command.effectiveTo,
    );
    final noOp = current.hasSameMutableValues(
      price: price,
      effectivePeriod: period,
      note: command.note,
    );

    if (!noOp) {
      _ensureReferencesAreValid(context, current);
      if (context.productUnit.isBelowFloor &&
          (!command.acknowledgeFloorWarning || !context.canOverrideFloor)) {
        throw PricingBlockedException(
          PricingBlockedCodes.belowFloorBlocked,
          details: {
            'reason': command.acknowledgeFloorWarning
                ? 'overridePermissionRequired'
                : 'acknowledgementRequired',
          },
        );
      }
      final outcome = RuleValidationOutcome.evaluateFloor(
        rulePrice: price,
        listPrice: _snapshotMoney(
          context.productUnit.listPriceMinor,
          current.price.currencyCode,
        ),
        floorPrice: _snapshotMoney(
          context.productUnit.floorPriceMinor,
          current.price.currencyCode,
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
      current.updateMutableFields(
        price: price,
        effectivePeriod: period,
        validationOutcome: outcome,
        note: command.note,
      );
    }

    return _commandGateway.update(
      candidate: current,
      expectedVersion: command.expectedVersion,
      acknowledgeFloorWarning: command.acknowledgeFloorWarning,
      acknowledgeOverwrite: command.acknowledgeOverwrite,
    );
  }

  void _ensureReferencesAreValid(
    CustomerPriceRuleUpdateContext context,
    CustomerPriceRule current,
  ) {
    final product = context.productUnit;
    final valid =
        context.customer.isValidForTransaction &&
        context.customer.customerId == current.key.customerId &&
        product.isSellable &&
        product.productId == current.key.productId &&
        product.productUnitId == current.key.productUnitId &&
        product.currencyCode.toUpperCase() == current.price.currencyCode;
    if (!valid) {
      throw const PricingBlockedException(PricingBlockedCodes.referenceInvalid);
    }
  }

  Money? _snapshotMoney(int? amountMinor, String currencyCode) {
    if (amountMinor == null || amountMinor <= 0) return null;
    return Money(amountMinor: amountMinor, currencyCode: currencyCode);
  }
}
