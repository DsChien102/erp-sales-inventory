import 'business_rule.dart';

class BusinessRuleValidationException implements Exception {
  late IBusinessRule _brokenRule;
  IBusinessRule get brokenRule => _brokenRule;

  late String _details;
  String get details => _details;

  BusinessRuleValidationException(IBusinessRule brokenRule) : super() {
    _brokenRule = brokenRule;
    _details = brokenRule.message;
  }

  @override
  String toString() {
    return "${brokenRule.runtimeType}: ${brokenRule.message}";
  }
}

extension EnsureRuleIsValid on IBusinessRule {
  void ensureValid() {
    if (isBroken()) {
      throw BusinessRuleValidationException(this);
    }
  }
}
