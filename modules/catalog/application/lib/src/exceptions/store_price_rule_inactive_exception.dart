import 'package:vet45_shared_application/application.dart';

final class StorePriceRuleInactiveException extends ApplicationException {
  StorePriceRuleInactiveException([String? message])
    : super(message ?? 'Store Price Rule is inactive.');
}
