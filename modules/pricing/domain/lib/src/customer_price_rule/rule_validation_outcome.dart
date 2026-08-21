import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'price_check_status.dart';
import 'rule_validation_state.dart';

final class RuleValidationOutcome extends ValueObject {
  RuleValidationOutcome({
    required this.outcome,
    required this.priceCheckStatus,
    this.warningCodes = const [],
    this.blockingCodes = const [],
    this.listPrice,
    this.floorPrice,
    this.floorPriceHidden = false,
  });

  factory RuleValidationOutcome.clear() => RuleValidationOutcome(
    outcome: RuleValidationState.valid,
    priceCheckStatus: PriceCheckStatus.normal,
  );

  factory RuleValidationOutcome.evaluateFloor({
    required Money rulePrice,
    Money? listPrice,
    Money? floorPrice,
    bool floorPriceHidden = false,
    bool acknowledgeFloorWarning = false,
    bool canOverrideFloor = false,
  }) {
    if (floorPrice == null) {
      return RuleValidationOutcome(
        outcome: RuleValidationState.valid,
        priceCheckStatus: PriceCheckStatus.notChecked,
        listPrice: listPrice,
        floorPriceHidden: floorPriceHidden,
      );
    }
    if (rulePrice.currencyCode != floorPrice.currencyCode ||
        (listPrice != null &&
            rulePrice.currencyCode != listPrice.currencyCode)) {
      return RuleValidationOutcome(
        outcome: RuleValidationState.blocked,
        priceCheckStatus: PriceCheckStatus.belowFloorBlocked,
        blockingCodes: const ['currency_mismatch'],
        listPrice: listPrice,
        floorPrice: floorPrice,
        floorPriceHidden: floorPriceHidden,
      );
    }
    if (rulePrice.amountMinor >= floorPrice.amountMinor) {
      return RuleValidationOutcome(
        outcome: RuleValidationState.valid,
        priceCheckStatus: PriceCheckStatus.normal,
        listPrice: listPrice,
        floorPrice: floorPrice,
        floorPriceHidden: floorPriceHidden,
      );
    }
    if (!acknowledgeFloorWarning) {
      return RuleValidationOutcome(
        outcome: RuleValidationState.blocked,
        priceCheckStatus: PriceCheckStatus.belowFloorBlocked,
        blockingCodes: const ['acknowledgement_required'],
        listPrice: listPrice,
        floorPrice: floorPrice,
        floorPriceHidden: floorPriceHidden,
      );
    }
    if (!canOverrideFloor) {
      return RuleValidationOutcome(
        outcome: RuleValidationState.blocked,
        priceCheckStatus: PriceCheckStatus.belowFloorBlocked,
        blockingCodes: const ['override_permission_required'],
        listPrice: listPrice,
        floorPrice: floorPrice,
        floorPriceHidden: floorPriceHidden,
      );
    }
    return RuleValidationOutcome(
      outcome: RuleValidationState.warning,
      priceCheckStatus: PriceCheckStatus.overrideAllowed,
      warningCodes: const ['below_floor_price'],
      listPrice: listPrice,
      floorPrice: floorPrice,
      floorPriceHidden: floorPriceHidden,
    );
  }

  final RuleValidationState outcome;
  final PriceCheckStatus priceCheckStatus;
  final List<String> warningCodes;
  final List<String> blockingCodes;
  final Money? listPrice;
  final Money? floorPrice;
  final bool floorPriceHidden;

  bool get isBlocked => outcome == RuleValidationState.blocked;

  @override
  List<Object?> get props => [
    outcome,
    priceCheckStatus,
    warningCodes,
    blockingCodes,
    listPrice,
    floorPrice,
    floorPriceHidden,
  ];
}
