import 'package:vet45_pricing_domain/domain.dart';

final class RememberedPriceOutcomeDto {
  const RememberedPriceOutcomeDto({
    required this.requestId,
    required this.resultType,
    required this.warnings,
    required this.isReplay,
    this.ruleId,
    this.ruleVersion,
    this.reasonCode,
  });

  final String requestId;
  final RememberedPriceResultType resultType;
  final String? ruleId;
  final int? ruleVersion;
  final String? reasonCode;
  final List<String> warnings;
  final bool isReplay;
}
