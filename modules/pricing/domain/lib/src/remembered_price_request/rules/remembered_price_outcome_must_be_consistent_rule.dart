import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../remembered_price_result_type.dart';

final class RememberedPriceOutcomeMustBeConsistentRule implements IBusinessRule {
  const RememberedPriceOutcomeMustBeConsistentRule({
    required this.resultType,
    required this.ruleId,
    required this.ruleVersion,
    required this.reasonCode,
  });

  final RememberedPriceResultType resultType;
  final String? ruleId;
  final int? ruleVersion;
  final String? reasonCode;

  @override
  bool isBroken() => switch (resultType) {
    RememberedPriceResultType.created || RememberedPriceResultType.updated =>
      ruleId == null ||
          ruleId!.trim().isEmpty ||
          ruleVersion == null ||
          ruleVersion! <= 0,
    RememberedPriceResultType.skipped || RememberedPriceResultType.blocked =>
      reasonCode == null || reasonCode!.trim().isEmpty,
  };

  @override
  String get message =>
      'Remembered price outcome fields are inconsistent with result type.';
}
