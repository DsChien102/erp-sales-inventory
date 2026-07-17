import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'rules/effective_period_must_be_valid_rule.dart';

final class EffectivePeriod extends ValueObject {
  EffectivePeriod({required DateTime effectiveFrom, DateTime? effectiveTo})
    : effectiveFrom = _dateOnly(effectiveFrom),
      effectiveTo = effectiveTo == null ? null : _dateOnly(effectiveTo) {
    ValueObject.checkRule(
      EffectivePeriodMustBeValidRule(
        effectiveFrom: this.effectiveFrom,
        effectiveTo: this.effectiveTo,
      ),
    );
  }

  final DateTime effectiveFrom;
  final DateTime? effectiveTo;

  bool overlaps(EffectivePeriod other) {
    final thisEndsAfterOtherStarts =
        effectiveTo == null || !effectiveTo!.isBefore(other.effectiveFrom);
    final otherEndsAfterThisStarts =
        other.effectiveTo == null ||
        !other.effectiveTo!.isBefore(effectiveFrom);
    return thisEndsAfterOtherStarts && otherEndsAfterThisStarts;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  @override
  List<Object?> get props => [effectiveFrom, effectiveTo];
}
