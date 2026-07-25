import 'money_dto.dart';

final class RuleValidationOutcomeDto {
  const RuleValidationOutcomeDto({
    required this.outcome,
    required this.warningCodes,
    required this.blockingCodes,
    required this.floorPriceHidden,
    this.listPrice,
    this.floorPrice,
  });

  final String outcome;
  final List<String> warningCodes;
  final List<String> blockingCodes;
  final MoneyDto? listPrice;
  final MoneyDto? floorPrice;
  final bool floorPriceHidden;
}
