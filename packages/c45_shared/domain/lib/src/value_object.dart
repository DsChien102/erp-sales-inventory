import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'business_rule.dart';
import 'business_rule_validation_exception.dart';

abstract class ValueObject extends Equatable {
  const ValueObject();

  @protected
  static void checkRule(IBusinessRule rule) {
    if (rule.isBroken()) {
      throw BusinessRuleValidationException(rule);
    }
  }

  @override
  List<Object?> get props;
}
