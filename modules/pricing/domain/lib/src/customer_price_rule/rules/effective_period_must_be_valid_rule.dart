import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class EffectivePeriodMustBeValidRule implements IBusinessRule {
  const EffectivePeriodMustBeValidRule({
    required this.effectiveFrom,
    this.effectiveTo,
  });

  final DateTime effectiveFrom;
  final DateTime? effectiveTo;

  @override
  bool isBroken() => effectiveTo?.isBefore(effectiveFrom) ?? false;

  @override
  String get message => 'Effective to must not be before effective from.';
}
